#!/usr/bin/env ruby

#
# Read output of diff command and output
# in format:
#  A: added files in target
#  D: deleted files in target
#  M: modified files in target
#
class DiffOutputTransformer
  
  @@source = ""
  @@target = ""
  @@ignores = []
  
  @@symbols = {
    :added   => 'A',
    :removed => 'D',
    :changed => 'U'
  }
  
  def self.input(input)
    @@input = input
    return self
  end

  def self.source(source)
    @@source = source
    return self
  end
  
  def self.target(target)
    @@target = target
    return self
  end
  
  def self.ignore?(filename)
    @@ignores.include? filename
  end
  
  def self.ignores( filename_to_ignore )
    
    if filename_to_ignore.kind_of? Array
      @@ignores.concat filename_to_ignore
    else
      @@ignores.push filename_to_ignore
    end
    
    return self
  end
  
  def self.transform
    
    yield( self )
    
    @@patterns = {
      :added   => /Only in (#{@@source}): ([\w.]*)/i,
      :removed => /Only in (#{@@target}): ([\w.]*)/i,
      :changed => /Files ((#{@@source}|#{@@target})([\w.\/]*)) and ((#{@@target}|#{@@source})([\w.\/]*)) differ/i
    }
    
    File.open( @@input ).each do | line |
      # Added
      a = @@patterns[:added].match( line )
      puts @@symbols[:added] + ": " + a[2]   if a and a[1] and a[2] and !self.ignore?(a[2])
      a = nil
      
      # Removed
      r = @@patterns[:removed].match( line )
      puts @@symbols[:removed] + ": " +  r[2]   if r and r[1] and r[2] and !self.ignore?(r[2])
      r = nil
      
      # Changed
      c = @@patterns[:changed].match( line )
      puts @@symbols[:changed] + ": " + c[3]  if c and c[3] and c[6]
      c = nil
    end
    
  end
end

#
# Runs the diff command between a source and target
# directory, outputting the results in the output_file
# NB: diff must be installed and in your system PATH
#
class DirDiffer
  
  def self.diff( source_dir, target_dir, output_file="/tmp/diff_dirs.log" )
    
    if source_dir and target_dir
      command = "diff --recursive --brief #{source_dir} #{target_dir} > #{output_file}"
    end
    
    result = system(command);

  end
  
end

require 'optparse'
options = { :output => "/tmp/diff_dirs.log", :ignore => ".svn" }

OptionParser.new do |opts|
  script_name = File.basename($0)
  opts.banner = "Usage: ruby #{script_name} [options]"

  opts.separator ""

  opts.on(  "-s", "--source source",
            "Specify the source directory to compare"
  ) { |options[:source]| }
  
  opts.on(  :REQUIRED, "-t", "--target target",
            "Specify the target directory to compare"
  ) { |options[:target]| }
  
  opts.on(  "-i", "--ignore ignore",
            "Don't compare files",
            options[:ignore]
  ) { |options[:ignore]| }
  
  opts.on(  "-o", "--output output",
            "Specify the temp output file",
            options[:output]
  ) { |options[:output]| }

  opts.separator ""

  opts.on("-h", "--help", "Show this help message.") do
    puts "help switch selected"
    puts opts
    exit
  end

end.parse!

unless options[:target] and options[:source]
  puts "No source or target given"
  exit
end

# Do the comparison
#
DirDiffer.diff( options[:source],
                options[:target],
                options[:output] )

DiffOutputTransformer.transform do | t |
  t.input( options[:output] )
  t.source( options[:source] )
  t.target( options[:target] )
  t.ignores( options[:ignore].split(",") )
end