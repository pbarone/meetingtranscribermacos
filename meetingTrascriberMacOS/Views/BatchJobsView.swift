//
//  BatchJobsView.swift
//  meetingTrascriberMacOS
//
//  Created by Kiro on 12/24/25.
//

import SwiftUI

// MARK: - Mock Data Models

enum BatchJobStatus: String, CaseIterable {
    case queued = "Queued"
    case uploading = "Uploading"
    case submitted = "Submitted"
    case processing = "Processing"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
    
    var color: Color {
        switch self {
        case .queued: return .orange
        case .uploading: return .blue
        case .submitted: return .indigo
        case .processing: return .purple
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
}

struct BatchJob: Identifiable {
    let id: String
    let sessionName: String
    let submittedAt: Date
    let duration: String
    var status: BatchJobStatus
    var errorMessage: String?
    var isSelected: Bool = false
}

// MARK: - Main View

struct BatchJobsView: View {
    @State private var selectedFilter: String = "All"
    @State private var searchText: String = ""
    @State private var mockJobs: [BatchJob] = []
    @State private var selectedJobIds: Set<String> = []
    
    private let statusFilters = ["All Jobs", "Active", "Completed", "Failed"]
    
    var filteredJobs: [BatchJob] {
        var jobs = mockJobs
        
        // Apply status filter
        if selectedFilter == "Active" {
            jobs = jobs.filter { $0.status == .queued || $0.status == .uploading || $0.status == .submitted || $0.status == .processing }
        } else if selectedFilter == "Completed" {
            jobs = jobs.filter { $0.status == .completed }
        } else if selectedFilter == "Failed" {
            jobs = jobs.filter { $0.status == .failed }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            jobs = jobs.filter { job in
                job.sessionName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return jobs
    }
    
    var jobStatistics: (active: Int, completed: Int, failed: Int, total: Int) {
        let active = mockJobs.filter { $0.status == .queued || $0.status == .uploading || $0.status == .submitted || $0.status == .processing }.count
        let completed = mockJobs.filter { $0.status == .completed }.count
        let failed = mockJobs.filter { $0.status == .failed }.count
        return (active, completed, failed, mockJobs.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Batch Job Management")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Monitor batch transcription jobs for enhanced accuracy.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // Filters and Search
                    HStack(spacing: 12) {
                        Picker("Status", selection: $selectedFilter) {
                            ForEach(statusFilters, id: \.self) { filter in
                                Text(filter).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 160)
                        
                        Spacer()
                        
                        TextField("Search by session name or file", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 300)
                        
                        Button(action: {
                            // Refresh action (mock)
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .help("Refresh job list")
                    }
                    .padding(.horizontal)
                    
                    // Summary Cards
                    HStack(spacing: 12) {
                        StatCard(title: "Active", count: jobStatistics.active, color: .primary)
                        StatCard(title: "Completed", count: jobStatistics.completed, color: .primary)
                        StatCard(title: "Failed", count: jobStatistics.failed, color: .primary)
                        StatCard(title: "Total", count: jobStatistics.total, color: .blue, isHighlighted: true)
                    }
                    .padding(.horizontal)
                    
                    // Bulk Actions
                    HStack(spacing: 12) {
                        Button("Remove from List") {
                            // Remove from list action (mock)
                        }
                        .buttonStyle(.bordered)
                        .disabled(selectedJobIds.isEmpty)
                        
                        Button("Delete Permanently") {
                            // Delete permanently action (mock)
                        }
                        .buttonStyle(.bordered)
                        .disabled(selectedJobIds.isEmpty)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Job List
                    VStack(spacing: 0) {
                        if filteredJobs.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                
                                Text(mockJobs.isEmpty ? "No batch transcription jobs found." : "No jobs match the current filters.")
                                    .foregroundStyle(.secondary)
                                
                                if mockJobs.isEmpty {
                                    Text("Jobs will appear here after recording.")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            ForEach(filteredJobs) { job in
                                JobItemView(
                                    job: job,
                                    isSelected: selectedJobIds.contains(job.id),
                                    onToggleSelection: {
                                        if selectedJobIds.contains(job.id) {
                                            selectedJobIds.remove(job.id)
                                        } else {
                                            selectedJobIds.insert(job.id)
                                        }
                                    }
                                )
                                
                                if job.id != filteredJobs.last?.id {
                                    Divider()
                                        .padding(.leading, 40)
                                }
                            }
                        }
                    }
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .onAppear {
            loadMockData()
        }
    }
    
    private func loadMockData() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        mockJobs = [
            BatchJob(
                id: "job-1",
                sessionName: "2025-12-18-12-32-45-Bedrock+ starter kit construct for Anthropic deals",
                submittedAt: dateFormatter.date(from: "2025-12-23 13:13:25")!,
                duration: "30m 28s",
                status: .completed
            ),
            BatchJob(
                id: "job-2",
                sessionName: "2025-12-22-15-23-18-Jerry & Paolo - Service Mix Conversation",
                submittedAt: dateFormatter.date(from: "2025-12-22 15:55:12")!,
                duration: "31m 22s",
                status: .completed
            ),
            BatchJob(
                id: "job-3",
                sessionName: "2025-12-18-12-32-45-Bedrock+ starter kit construct for Anthropic deals",
                submittedAt: dateFormatter.date(from: "2025-12-19 12:24:08")!,
                duration: "30m 28s",
                status: .completed
            ),
            BatchJob(
                id: "job-4",
                sessionName: "2025-12-19-11-59-03-Globant - AWS _ Amazon Connect (REAL)",
                submittedAt: dateFormatter.date(from: "2025-12-19 12:23:43")!,
                duration: "24m 8s",
                status: .completed
            ),
            BatchJob(
                id: "job-5",
                sessionName: "2025-12-19-10-31-22-Deloitte ME Demo Discussion",
                submittedAt: dateFormatter.date(from: "2025-12-19 11:02:20")!,
                duration: "30m 53s",
                status: .completed
            ),
            BatchJob(
                id: "job-6",
                sessionName: "2025-12-17-15-48-56-Rumi chat",
                submittedAt: dateFormatter.date(from: "2025-12-17 16:08:58")!,
                duration: "20m 4s",
                status: .completed
            ),
            BatchJob(
                id: "job-7",
                sessionName: "2025-12-17-15-01-38-[internal] Deloitte Project Vector_ One Team Meeting",
                submittedAt: dateFormatter.date(from: "2025-12-17 15:30:38")!,
                duration: "29m 22s",
                status: .completed
            ),
            BatchJob(
                id: "job-8",
                sessionName: "2025-12-16-09-15-42-abc123",
                submittedAt: dateFormatter.date(from: "2025-12-16 10:05:15")!,
                duration: "45m 12s",
                status: .processing
            ),
            BatchJob(
                id: "job-9",
                sessionName: "2025-12-15-14-20-11-xyz789",
                submittedAt: dateFormatter.date(from: "2025-12-15 15:10:30")!,
                duration: "18m 45s",
                status: .failed,
                errorMessage: "Audio file format not supported"
            )
        ]
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let count: Int
    let color: Color
    var isHighlighted: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(isHighlighted ? Color.blue.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }
}

struct JobItemView: View {
    let job: BatchJob
    let isSelected: Bool
    let onToggleSelection: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            
            // Left side: Job info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(job.sessionName)
                        .font(.system(size: 13))
                        .fontWeight(.medium)
                    
                    if job.status == .completed {
                        Button(action: {
                            // Rename action (mock)
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 11))
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                        .help("Rename session")
                    }
                }
                
                HStack(spacing: 16) {
                    Text("Submitted: \(dateFormatter.string(from: job.submittedAt))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    Text("Duration: \(job.duration)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                if let errorMessage = job.errorMessage {
                    Text("Error: \(errorMessage)")
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
            
            // Right side: Status and actions
            VStack(alignment: .trailing, spacing: 8) {
                Text(job.status.rawValue)
                    .font(.system(size: 12))
                    .fontWeight(.semibold)
                    .foregroundStyle(job.status.color)
                
                HStack(spacing: 8) {
                    if job.status == .completed {
                        Button("Open Transcript") {
                            // Open transcript action (mock)
                        }
                        .buttonStyle(.link)
                        .controlSize(.small)
                        
                        Button("Open Folder") {
                            // Open folder action (mock)
                        }
                        .buttonStyle(.link)
                        .controlSize(.small)
                    }
                    
                    if job.status == .failed {
                        Button("Retry") {
                            // Retry action (mock)
                        }
                        .buttonStyle(.link)
                        .controlSize(.small)
                    }
                    
                    if job.status == .uploading || job.status == .processing || job.status == .submitted {
                        Button("Cancel") {
                            // Cancel action (mock)
                        }
                        .buttonStyle(.link)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding(12)
        .contentShape(Rectangle())
    }
}

#Preview {
    BatchJobsView()
        .frame(width: 900, height: 700)
}
