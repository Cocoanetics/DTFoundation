#!/usr/bin/env ruby

require 'etc'
require 'fileutils'
require 'find'

workingDir = Dir.getwd
derivedDataDir = "#{Etc.getpwuid.dir}/Library/Developer/Xcode/DerivedData/"
 
outputDir = workingDir + "/gcov"
FileUtils.mkdir outputDir 
 
Find.find(derivedDataDir) do |file|
  if file.match(/\.gcda\Z/)
     
      #get just the folder name
      gcov_dir = File.dirname(file)
     
      #chdir because gcov cannot work with absolute path
      Dir.chdir gcov_dir

      #process the file
      system("gcov '#{file}' -o '#{gcov_dir}'")
      
      Dir.glob("*.gcov") do |file|
        FileUtils.mv(file, outputDir)
      end
   end
end

#change back to working directory
Dir.chdir workingDir

#call the coveralls
system 'coveralls', '--verbose'

#clean up
FileUtils.rm_rf outputDir
