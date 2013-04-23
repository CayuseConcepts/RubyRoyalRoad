#!/usr/bin/env ruby
#######################################################################
#  Royal Road wrapper - Runs the Royal Road experiment specifying
#  either the expereiment 1A schema, or the experiment 1B schema.
#
#  usage:  runRoyal.rb <1A | 1B> 
#
#######################################################################

require 'royalRoad.rb'

exp1B   = false;
overlap = false;

# There must be an argument passed in of either '1A' or '1B'
if (ARGV[0] == "1A") then
  exp1B = false 
elsif (ARGV[0] == "1B") then
  exp1B = true
else
  print "usage: runRoyal.rb <1A [O]| 1B> \n";
  exit(0)
end

# run the overlap if present
if ((ARGV[0] == "1A") && (ARGV[1] == "O")) then
  overlap = true
end

# Run the Genetic algorithm
rr = RoyalRoad.new(exp1B, overlap)
rr.findOptimal

# print the number of generations to find the optimal.  0 if not found
print "#{rr.generations}\n"

# For each run, print the percentages of a present s8 schema for all
# generations.
print "s8%, "
rr.generations.times {
  |gen|
  print "#{rr.p8[gen]},"
}
print "\n"

# If we are doing experiment 1B, then print the percentages of a present 
# s12 and s14 schema for all generations
if (exp1B) then
  print "s12%, "
  rr.generations.times {
    |gen|
    print "#{rr.p12[gen]},"
  }
  print "\n"

  print "s14%, "
  rr.generations.times {
    |gen|
    print "#{rr.p14[gen]},"
  }
  print "\n"

end

print "\n"
