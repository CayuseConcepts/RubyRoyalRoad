#!/usr/bin/env ruby

#######################################################################
# RoyalRoad
# Implements the Royal Road Genetic Algorithm experiment.  Basic Algorithm:
# 1. Initialize the population with 128 random individuals.
# 2. Sort the population according to fitness
# 3. Allow the 10 fittest individuals to pass to the next generation
# 4. Mate 59 times, selecting from the full population, with possible crossover
# 5. If after a mating, an optimal individual is discovered, terminate
#    the population and return the generation number
# 6. Allow mutation to potentially mutate some of the bits in the new
#    118 children
# 7. The new population consists of the fittest 10, plus the new 118
#    offspring
# 8. Take the new population and goto step 2.
#######################################################################
class RoyalRoad

  GENERATIONS    = 1500
  POPULATION     = 128
  CROSSOVER_RATE = 0.7
  MUTATION_RATE  = 0.005
  ELITE_NUMBER   = 42

  attr_reader :population, :schema, :generations, :p8, :p12, :p14

  # Constructor - Create a schema, and create an initial population
  def initialize(schema14=false, overlap=false)

    @@schema14 = schema14
    @@overlap  = overlap
    @@optimalScore = 0;

    @generations = 0

    # These arrays keep track of the schema 8, 12, and 14 percentages
    @p8  = Array.new
    @p12 = Array.new
    @p14 = Array.new

    @population = Population.new

    if (overlap) then
      SchemaOverlap.create
      @@optimalScore = 100
    else
      # Create a schema object, based on whether there are 8 or 14 schema.
      # @@schema14 = true if we want the full schema, false if not
      Schema.create(@@schema14)
      if (@@schema14) then
        @@optimalScore = 240
      else
        @@optimalScore = 80
      end
    end

    print "Optimal score = #{@@optimalScore}\n"

    POPULATION.times {
      @population.addIndividual(RandomIndividual.new(@@schema14, @@overlap))
    }

    @population.setup

  end

  # findOptimal - Generates a new generation until an optimal individual
  #               is found, or the maximum number of generations is met.
  def findOptimal
    GENERATIONS.times {
      |gen|
      (p8[gen], p12[gen], p14[gen]) = @population.getSchemaStats
      if (nextGeneration) then
        @generations = gen
        break
      end
    }
  end


  # nextGeneration - Perform all the operations to create a successive
  #                  generation from the current one.  Returns true if
  #                  an optimal individual is found, false otherwise
  def nextGeneration
    newPopulation = Population.new
   
    # Take the ten fittest individuals from the existing population.
    # (Array is sorted from low to high fitness, so take the last 10)
    (POPULATION - 1).downto(POPULATION - ELITE_NUMBER) {
      |idx|
      newPopulation.addIndividual(@population.individuals[idx])
    }

    # now select and mate the rest of the population
    ((POPULATION - ELITE_NUMBER)/2).times {
      p1 = @population.select
      p2 = @population.select

      # Create two children from the two parents
      (c1, c2) = mate(p1, p2)

      # Check if one of our children is an optimal
      if ((c1.score == @@optimalScore) || (c2.score == @@optimalScore)) then
        return true
      end
      
      newPopulation.addIndividual(c1)
      newPopulation.addIndividual(c2)
    }

    @population = newPopulation;
    @population.setup

    return false;
  end

  # mate - Use two parents to create two new children
  def mate (p1, p2)
    srand

    # If the random number 0 < rand < 1 is less than the RATE, then crossover,
    # else just copy the parents directly to the children
    if (rand < CROSSOVER_RATE) then
      (c1, c2) = crossover(p1, p2)
    else 
      c1 = p1
      c2 = p2
    end

    c1 = mutate(c1)
    c2 = mutate(c2)

    return [c1, c2]
  end

  # crossover - Crossover two parents, using random single-point crossover
  def crossover(p1, p2)
    # Crossover at 0 or 63 is not really crossover, so we will choose our
    # crossover point to be between 1 and 62
    point = (rand * 61).round + 1

    s1 = p1.bitString
    s2 = p2.bitString

    left1  = s1[0..(point-1)]
    right1 = s1[point..63]
    left2  = s2[0..(point-1)]
    right2 = s2[point..63]

    c1 = Individual.new(left1 + right2, @@schema14, @@overlap)
    c2 = Individual.new(left2 + right1, @@schema14, @@overlap)

    return [c1,c2]
  end
  
  # mutate - With probability MUTATION_RATE, flip each bit in the individual
  def mutate(ind)

    # Don't bother to mutate if we have set the rate to zero
    return ind if (MUTATION_RATE == 0)

    s1 = ind.bitString

    srand

    64.times {
      |idx|
      if (rand < MUTATION_RATE) then
          if (s1[idx,1] == "0") then
            s1[idx,1] = "1"
          else
            s1[idx,1] = "0"
          end
      end
    }

    return Individual.new(s1, @@schema14, @@overlap)
  end

end




#######################################################################
# Schema - a singleton class
# Defines the royal road schemas used by the fitness function
# in the Individual class.  Each schema array defines the start and
# end position of the 1's group, and the wieght given to the schema.
#######################################################################
class Schema

  private_class_method :new
  @@schema = nil
  @@schemas = nil

  def Schema.create(wholeEnchilada)
    @@schema = new(wholeEnchilada) unless @@schema
    @@schema
  end

  def initialize(wholeEnchilada)
    @@schemas = Array.new
    @@schemas[0]  = [0,7,1]
    @@schemas[1]  = [8,15,1]
    @@schemas[2]  = [16,23,1]
    @@schemas[3]  = [24,31,1]
    @@schemas[4]  = [32,39,1]
    @@schemas[5]  = [40,47,1]
    @@schemas[6]  = [48,55,1]
    @@schemas[7]  = [56,63,1]

    if (wholeEnchilada) then
      @@schemas[8]  = [0,15,2] 
      @@schemas[9]  = [16,31,2]
      @@schemas[10] = [32,47,2]
      @@schemas[11] = [48,63,2]
      @@schemas[12] = [0,31,4]
      @@schemas[13] = [32,63,4]
    end
  end

  def Schema.check(schIdx, string)

    # Loop through all the bit positions in the string, as defined by
    # the schema array at 'schIdx'.  If we hit a zero anywhere, then
    # return a score of 0
    @@schemas[schIdx][0].upto(@@schemas[schIdx][1]) {
      |bitPos|
      return 0 if string[bitPos,1] == "0"
    }
    
    # If we made it here, then the group of bits in the schema were all 1's.

    # return the weight score defined in the schema
     @@schemas[schIdx][2]
  end

end

#######################################################################
# SchemaOverlap
# Implements an overlapping schema
#######################################################################
class SchemaOverlap < Schema

  def SchemaOverlap.create
    @@schema = new unless @@schema
    @@schema
  end

  def initialize
    super(false)
    @@schemas[0]  = [0,9,1]
    @@schemas[1]  = [6,15,1]
    @@schemas[2]  = [12,21,1]
    @@schemas[3]  = [18,27,1]
    @@schemas[4]  = [24,33,1]
    @@schemas[5]  = [30,39,1]
    @@schemas[6]  = [36,45,1]
    @@schemas[7]  = [42,51,1]
    @@schemas[8]  = [48,57,1]
    @@schemas[9]  = [54,63,1]
  end
end

#######################################################################
# Individual
# Defines a individual in the population.  An individual consists of a
# bit string (a chromosome) and a fitness score.  The fitness score
# is calculated using a royal road method.
#######################################################################
class Individual

  RR1_SCHEMA     = 8
  RR2_SCHEMA     = 14
  OVERLAP_SCHEMA = 10
  STRING_LEN     = 64

  attr_reader :bitString, :score, :s8, :s12, :s14

  # Constructor - initialized the bit string with the given string, and
  #               calculates the fitness of the bit string
  def initialize(bitString, schema14=false, overlap=false)
    if (overlap) then
      @@schema_size = OVERLAP_SCHEMA
    elsif (schema14) then
      @@schemaSize = RR2_SCHEMA
    else
      @@schemaSize = RR1_SCHEMA
    end
    
    @s8 = @s12 = @s14 = false

    @bitString = bitString
    @score = fitness
  end

  # fitness - Defines the fitness function.  For this experiment, uses
  #           the schemas defined in the Schema class to implement a
  #           Royal Road function
  def fitness
    myScore = 0
    
    @@schemaSize.times{|idx|
      partScore = Schema.check(idx, bitString)
      if (partScore > 0) then
        @s8  = true if (idx == 7)
        @s12 = true if (idx == 11)
        @s14 = true if (idx == 13)
        myScore = myScore + partScore
      end
    }     

    # We can't have scores of zero, so everyone has a base of 1.
    # If there is a score, make it 10 times the score, else just
    # make it 1.  That way, there is no individual with a ZERO
    # chance of reproduction.
    if (myScore > 0) then 
      myScore = myScore * 10
    else
      myScore = 1
    end

    myScore
  end
end




#######################################################################
# RandomIndividual
# Inherits from Inidividual.  The only difference is that this class
# initializes with a randomly generated bit string.
#######################################################################
class RandomIndividual < Individual

  def initialize(schema14=false, overlap=false)
    randString = "";
    srand
    STRING_LEN.times { randString << "#{rand(2)}" }
    super(randString, schema14);
  end
end




#######################################################################
# Population
# Defines the entire population.  Allows operations on the population 
# such as sorting, selection, addition and deletion of an individual,
# and the identification of the top 10 fittest individuals.
#######################################################################
class Population

  attr_reader :individuals

  # Constructor - creates the basic individuals array and population
  #               parameters
  def initialize
    @individuals = Array.new
    @avgScore    = 0
    @sumScore    = 0
  end

  # setup - Sorts the population, gets a sum of the fitness scores, and
  #         calculates the average fitness for use later in selection
  def setup
    sort
    @individuals.each {|ind| @sumScore = @sumScore + ind.score }
  end

  # sort - an in-place sort of all individuals
  def sort
    @individuals.sort!{|a,b| a.score <=> b.score}
  end

  # select - Performs fitness proportional selection.  First generates a
  #          random number between 0 and sumScore (sum of all fitnesses).
  #          Then starts out with the least fit indiviual, and loops through
  #          all individuals, adding the fitness scores.  Once an individual
  #          ....
  def select
    expectedSum = 0

    # Now we choose a random integer betweeen 0 and @sumScore
    srand
    target = rand(@sumScore).round

    # Finally, sum the score for every individual, and when the
    # sum meets or exceeds the random target, select that individual
    @individuals.size.times {
      |idx|
      expectedSum = expectedSum + @individuals[idx].score
      return @individuals[idx] if (expectedSum >= target)
    }

    # If we made it all the way here, then just return the last individual
    return @individuals[(@individuals.size - 1)]
  end

  # addIndividual - adds an individual to the population
  def addIndividual(individual)
    @individuals.push(individual)
  end


  # getSchemaStats - checks all the individuals for the specified schemas,
  #                  and keeps track of them.  Returns a percentage of the
  #                  total population for s8, s12, and s14
  def getSchemaStats
    sch8 = sch12 = sch14 = 0
    p8 = p12 = p14 = 0
    @individuals.size.times {
      |idx|
      sch8  = sch8  + 1 if @individuals[idx].s8
      sch12 = sch12 + 1 if @individuals[idx].s12
      sch14 = sch14 + 1 if @individuals[idx].s14
    }
    p8  = ((sch8/@individuals.size.to_f) * 100).round
    p12 = ((sch12/@individuals.size.to_f) * 100).round
    p14 = ((sch14/@individuals.size.to_f) * 100).round
    
    return [p8, p12, p14]
  end

end

