def mySum(*args):
    total = 0
    for i in args:
        total += i
    return total

def myFunc(a, b, *args):
    return f'{a=}, {b=}, {args=}'
