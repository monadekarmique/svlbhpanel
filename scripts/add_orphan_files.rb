#!/usr/bin/env ruby
# Add 3 orphaned Swift files to the SVLBH Panel target in the Xcode project
# Run: ruby scripts/add_orphan_files.rb

require 'xcodeproj'

PROJECT_PATH = '/Users/patricktest/Developer/svlbhpanel-v5/SVLBH Panel.xcodeproj'
TARGET_NAME = 'SVLBH Panel'

# [ relative_path_from_main_group, containing_group_name ]
FILES_TO_ADD = [
  { path: 'SVLBH Panel/Demandes/DemandesView.swift',           group: %w[SVLBH\ Panel Demandes] },
  { path: 'SVLBH Panel/Views/ChronoFuTab.swift',               group: %w[SVLBH\ Panel Views] },
  { path: 'SVLBH Panel/Tore/ToreGlycemieScleroseView.swift',   group: %w[SVLBH\ Panel Tore] },
]

project = Xcodeproj::Project.open(PROJECT_PATH)
target = project.targets.find { |t| t.name == TARGET_NAME }
abort("Target '#{TARGET_NAME}' not found") unless target

puts "Target: #{target.name}"
puts "Current source files in target: #{target.source_build_phase.files.count}"

def find_or_create_group(project, path_components)
  group = project.main_group
  path_components.each do |name|
    # Try to find existing group with this name
    child = group.groups.find { |g| g.display_name == name || g.name == name || g.path == name }
    unless child
      # Create as a child group relative to parent, using name as path
      child = group.new_group(name, name)
    end
    group = child
  end
  group
end

added = 0
skipped = 0

FILES_TO_ADD.each do |entry|
  abs_path = File.join(File.dirname(PROJECT_PATH), entry[:path])
  unless File.exist?(abs_path)
    puts "[SKIP] File missing on disk: #{abs_path}"
    skipped += 1
    next
  end

  # Skip if already in the target
  basename = File.basename(entry[:path])
  already = target.source_build_phase.files.any? { |bf| bf.file_ref && bf.file_ref.path && bf.file_ref.path.end_with?(basename) }
  if already
    puts "[SKIP] Already in target: #{basename}"
    skipped += 1
    next
  end

  # Find or create parent group (e.g., SVLBH Panel/Demandes)
  group_names = entry[:group].map { |g| g.gsub('\\ ', ' ') }
  parent_group = find_or_create_group(project, group_names)

  # Create file reference
  file_ref = parent_group.new_reference(abs_path)
  # Use path relative to parent group
  file_ref.source_tree = '<group>'
  file_ref.path = basename

  # Add to target's sources build phase
  target.source_build_phase.add_file_reference(file_ref)

  puts "[ADD]  #{entry[:path]}"
  added += 1
end

if added > 0
  project.save
  puts "\nSaved project. Added #{added}, skipped #{skipped}."
  puts "New source files count: #{target.source_build_phase.files.count}"
else
  puts "\nNo changes made (added=#{added}, skipped=#{skipped})."
end
