#!/usr/bin/env ruby

require 'fileutils'


workingDir = Dir.getwd

# get xcode variables
xcodeBuildSettings = `xctool -project DTFoundation.xcodeproj -configuration Coverage -scheme "Static Library" clean -sdk iphonesimulator -showBuildSettings`

# hash table to keep them while we iterate over them
envVars = Hash.new

# pattern for each line
LINE_PATTERN = Regexp.new(/^\s*(.*?)\s=\s(.*)$/)

# extract the variables 
xcodeBuildSettings.each_line do |line|
  match = LINE_PATTERN.match(line)
        
  #store found variable in hash      
  if (match)
    envVars[match[1]] = match[2]
  end
end

object_file_dir = envVars["OBJECT_FILE_DIR_normal"]
current_arch = envVars["CURRENT_ARCH"]

#only proceed if we have those values
if (!object_file_dir || !current_arch)
  puts "Cannot find OBJECT_FILE_DIR_normal and CURRENT_ARCH, aborting\n"
  exit
end

#construct location of coverage files
gcov_dir=envVars["OBJECT_FILE_DIR_normal"] + "/" +  envVars["CURRENT_ARCH"] + "/"

puts "Scanning Folder: #{gcov_dir}"

# change into this directoy which might contain spaces
Dir.chdir gcov_dir

# enumerate over gcda files
Dir.glob("*.gcda") do |file|
  system("gcov #{file} -o '#{gcov_dir}'")
end

#change back to working directory
Dir.chdir workingDir

#copy entire objects_normal folder to gcov subfolder in working dir
FileUtils.cp_r gcov_dir, "gcov"

#call the coveralls
system 'coveralls', '--verbose'

#clean up
FileUtils.rm_rf("gcov")

