import sys

x, y, xx, yy = [str(int(float(x)*1000)) for x in sys.argv[1:]];
print( '(({} {}, {} {}, {} {}, {} {}, {} {}))'.format(x, y, xx, y, xx, yy, x, yy, x, y))
