def printer(s1, s2):
    print(f"WOW, this {s1} is so {s2}!")


printer('shit', 'easy')
printer('stuff', 'dumb')



a = [1, 2, 3]
b = [5, 6, 7]
c = [9, 10, 11]

for av, bv, cv in zip(a, b, c):
    print(av, bv, cv)
