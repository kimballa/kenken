
KenKen
=======

Solver for the game of KenKen!

This solves a math puzzle, as described here:
http://en.wikipedia.org/wiki/KenKen


Running:
--------

    ./kenken.rb <filename>

File Format
-----------

You specify a KenKen board in a text file as follows:

Each heavily-outlined section (called "cages" in the wikipedia page) is referred
to as a "domain" in this program's parlance.

Choose a unique symbol (e.g., letter) for each domain. In an NxN puzzle, the
first N lines of the file represent the board itself, identifying which domain
each cell of the puzzle belongs to. 

A 5x5 board might look something like:

    AAABC
    DDBBC
    DEEFF
    GGHHH
    IIHJJ

Each unique symbol (i.e., letter) in the string represents the name of a
different domain. There should be as many columns as rows (lines) in the
board.

This should be followed by a blank line, followed by the list of constraints.
The constraints are listed one per line as:

    <domain-letter> <operation> <goal>

e.g.:

    A + 5
    B * 24
    etc...

which indicates that all of the cells in domain A must sum to 5; all of
the cells in domain B must have a product of 24, and so forth.

