#!/usr/bin/env ruby

# A set of elements that need to be unified by an arithmetic operation to produce a goal value.
class Domain
  def initialize(name, op, goal)
    @name = name
    @op = op
    @goal = goal.to_i
  end

  attr_accessor :name

  # Given a collection of candidate values, return true if they can be unified
  # by the given operation to produce the goal value, false otherwise.
  #
  # e.g., for a set of two items with a goal value of 6 and an operation of '+',
  # the values [4, 2] or [1, 5] would unify, as would [2, 4] and [5, 1].
  def unify(candidates)
    # print "Check dom " + @name + " (" + @op + ") = " + @goal.to_s + ": " + candidates.to_s + "\n"
    if @op == '+' || @op == '-'
      unify_aux(0, candidates)
    else # *, /
      unify_aux(1, candidates)
    end
  end

  protected

  def unify_aux(accumulator, candidates)
    if candidates == [] || candidates.nil?
      return accumulator == @goal
    end

    candidates.each_with_index do |candidate, idx|
      if candidate.nil?
        # We haven't filled out the entire domain yet.
        return true # Implying that so far, we are okay to continue.
      elsif @op == '-'
        next_val = candidate - accumulator
      elsif @op == '+'
        next_val = candidate + accumulator
      elsif @op == '/'
        next_val = candidate / accumulator
      elsif @op == '*'
        next_val = candidate * accumulator
      end

      next_candidates = candidates.dup
      next_candidates.delete_at(idx)
      if unify_aux(next_val, next_candidates)
        return true
      end
    end

    return false
  end
end


class Board
  def initialize(board_string)
    parse(board_string)
  end

  # Given a multi-line string representing the rows of the board, map the board
  # into a set of Domains. A Board might look something like:
  #
  #     AAABC
  #     DDBBC
  #     DEEFF
  #     GGHHH
  #     IIHJJ
  #
  # Each unique symbol (i.e., letter) in the string represents the name of a
  # different domain. There should be as many columns as rows (lines) in the
  # board.
  #
  # This should be followed by a blank line, followed by the list of constraints.
  # These are listed one per line as:
  #
  # <domain-letter> <operation> <goal>
  #
  # e.g.:
  #
  #    A + 5
  #    B * 24
  #
  # etc.
  def parse(board_strings)
    @rows = []
    @domains = {}
    @max = board_strings.split("\n").first.size # Width of board == Max integer to include

    constraint_mode = false
    board_strings.split("\n").each do |line|
      line.strip!
      if (line == "" && !constraint_mode)
        constraint_mode = true
        next # We are now parsing constraints.
      elsif line == ""
        next # Skip subsequent blank lines
      elsif constraint_mode
        # Add a domain constraint.
        dom = Domain.new(*line.split(" "))
        @domains[dom.name] = dom
      else
        # This is a row of the board listing the domains within the row by letter..
        @rows << line.split("")
      end
    end
  end

  def solve
    # Start with a blank board.
    empty_lines = []
    Range.new(1, @max).each do |i|
      empty_line = [nil] * @max
      empty_lines << empty_line
    end
    attempt = empty_lines

    if !guess_and_check(attempt, 0, 0)
      print "Could not solve it!\n"
      p @rows
      p @domains
      p @max
      p attempt
    else
      print "SOLVED:\n"
      attempt.each do |row|
        row.each do |col|
          print col.to_i.to_s + " "
        end
        print "\n"
      end
    end
  end

  protected

  def guess_and_check(attempt, row, col)
    if col < 0
      raise RuntimeError.new("Negative column?!")
    elsif col >= @max
      # Time to move to the next row
      return guess_and_check(attempt, row + 1, 0)
    elsif row >= @max
      # We are finished with the board
      raise RuntimeError.new("Finished with the board / overflow?")
    end

    Range.new(1, @max).each do |v|
      # print row.to_s + ", " + col.to_s + ": " + v.to_s + "\n"
      attempt[row][col] = v * 1.0
      if col_ok(attempt, col) && row_ok(attempt, row) && domains_ok(attempt)
        if complete(attempt)
          # We're done!
          return true # Found it.
        else
          # We are so far so good, keep going. If this returns true, we've filled out the
          # array correctly. If this returns false, keep trying new values for this position.
          if guess_and_check(attempt, row, col + 1)
            # We found the solution via recursion! Keep returning true
            return true
          end
        end
      end
    end

    # Didn't find a satisfactory value here. backtrack.
    attempt[row][col] = nil
    return false
  end

  # Return true if the specified row contains no duplicate values.
  def row_ok(attempt, row)
    found = [false] * @max
    attempt_row = attempt[row]
    attempt_row.each do |v|
      if v.nil?
        next
      elsif found[v]
        #print "Found value twice in row: " + v.to_s + "\n"
        return false # Found a value twice.
      end

      found[v] = true
    end
    #print "Row ok\n"
    return true
  end

  # Return true if the specified column contains no duplicate values.
  def col_ok(attempt, col)
    found = [false] * @max
    attempt_col = []
    #print "Checking column " + col.to_s + "\n"
    attempt.each do |row|
      #p row
      attempt_col << row[col]
    end
    #p attempt_col
    attempt_col.each do |v|
      if v.nil?
        next
      elsif found[v]
        #print "Found value twice in col: " + v.to_s + "\n"
        return false # Found a value twice.
      end
      found[v] = true
    end
    #print "col ok\n"
    return true
  end

  # Return true if the board is totally filled out.
  def complete(attempt)
    attempt.each do |row|
      row.each do |c|
        if c.nil?
          return false
        end
      end
    end
    return true # Looks ok!
  end

  # Return true if all the constraint domains are satisfied or still satisfiable.
  # Return false if a domain has a constraint violation in it.
  def domains_ok(attempt)
    @domains.each do |(name, dom)|
      candidates = []
      @rows.each_with_index do |row, r|
        row.each_with_index do |d, c|
          if d == name
            candidates << attempt[r][c]
          end
        end
      end
      if !dom.unify(candidates)
        # Constraint violation for this domain.
        return false
      end
    end
    return true # All domains ok!
  end
end

def main(argv)
  filename = argv[0]
  if filename.nil?
    print "You need a filename argument!"
    exit 1
  end
  board = Board.new(File.read(filename))
  board.solve
end

main(ARGV)
