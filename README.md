RubyRoyalRoad
=============

Royal Road Genetic Algorithm in Ruby
------------------------------------

Implements the Royal Road Genetic Algorithm experiment.  Basic Algorithm:

1. Initialize the population with 128 random individuals.
2. Sort the population according to fitness
3. Allow the 10 fittest individuals to pass to the next generation
4. Mate 59 times, selecting from the full population, with possible crossover
5. If after a mating, an optimal individual is discovered, terminate the population 
   and return the generation number
6. Allow mutation to potentially mutate some of the bits in the new 118 children
7. The new population consists of the fittest 10, plus the new 118 offspring
8. Take the new population and goto step 2.

Use the runRoyal.rb to run the experiment non-interactively as a program.

Usage:

- runRoyal.rb 1A        - runs the 1A experiment without overlap
- runRoyal.rb 1A O      - runs the 1A experiment with overlap
- runRoyal.rb 1B        - runs the 1B experiemnt
   
   
See the article at http://cayu.se/technology/the-royal-road/ for a full explanation 
of the experiments and the rational for the code and its parameters.