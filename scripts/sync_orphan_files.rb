#!/usr/bin/env ruby
# Scan all .swift files under SVLBH Panel/ and add any that are NOT already in the SVLBH Panel target.
# Run: ruby scripts/sync_orphan_files.rb

require 'xcodeproj'
require 'set'

PROJECT_PATH = '/Users/patricktest/Developer/svlbhpanel-v5/SVLBH Panel.xcodeproj'
ROOT_DIR     = '/Users/patricktest/Developer/svlbhpanel-v5'
SOURCE_DIR   = File.join(ROOT_DIR, 'SVLBH Panel')
TARGET_NAME  = 'SVLBH Panel'

# Paths to exclude (test targets, Preview Content, etc.)
EXCLUDE_DIRS = [
  'SVLBH Panel/Preview Content',
]

project = Xcodeproj::Project.open(PROJECT_PATH)
target  = project.targets.find { |t| t.name == TARGET_NAME }
abort("Target '#{TARGET_NAME}' not found") unless target

# Collect all files already in the target's source_build_phase (by absolute path)
already_in_target = Set.new
target.source_build_phase.files.each do |bf|
  ref = bf.file_ref
  next unless ref
  # Resolve to absolute path
  begin
    abs = ref.real_path.to_s
  rescue => _
    abs = nil
  end
  already_in_target << abs if abs
end

puts "Files currently in target: #{already_in_target.size}"

# Walk all .swift files on disk under SVLBH Panel/
swift_files = Dir.glob(File.join(SOURCE_DIR, '**', '*.swift')).sort

# Filter out excluded dirs
swift_files.reject! do |f|
  rel = f.sub("#{ROOT_DIR}/", '')
  EXCLUDE_DIRS.any? { |ex| rel.start_with?(ex) }
end

puts "Swift files on disk (SVLBH Panel dir): #{swift_files.size}"

def find_or_create_group(project, rel_dirs)
  group = project.main_group
  rel_dirs.each do |name|
    child = group.groups.find { |g| (g.display_name == name) || (g.name == name) || (g.path == name) }
    unless child
      child = group.new_group(name, name)
    end
    group = child
  end
  group
end

added = 0
swift_files.each do |abs_path|
  next if already_in_target.include?(abs_path)

  rel = abs_path.sub("#{ROOT_DIR}/", '')         # e.g. "SVLBH Panel/Demandes/DemandesModels.swift"
  parts = rel.split('/')
  dirs  = parts[0..-2]                           # e.g. ["SVLBH Panel","Demandes"]
  basename = parts[-1]

  parent = find_or_create_group(project, dirs)
  file_ref = parent.new_reference(abs_path)
  file_ref.source_tree = '<group>'
  file_ref.path = basename
  target.source_build_phase.add_file_reference(file_ref)

  puts "[ADD] #{rel}"
  added += 1
end

if added > 0
  project.save
  puts "\nAdded #{added} orphan Swift file(s)."
  puts "New source files count in target: #{target.source_build_phase.files.count}"
else
  puts "\nNo orphans found. Target is in sync with disk."
end
