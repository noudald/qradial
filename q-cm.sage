from que import Monomial, Polynomial

print('=== Start q-cm.sage ===')

q = var('q')

E1 = Monomial(1, ['E1'])
E2 = Monomial(1, ['E2'])
F1 = Monomial(1, ['F1'])
F2 = Monomial(1, ['F2'])
K1 = Monomial(1, ['K1'])
K2 = Monomial(1, ['K2'])
K1inv = Monomial(1, ['K1'], [-1])
K2inv = Monomial(1, ['K2'], [-1])

c1, c2, d1, d2 = var('c1 c2 d1 d2')

l = var('l')

# B1c = F1 - c1 * E2*K1inv
# B2c = F2 - c2 * E1*K2inv
# B1d = F1 - d1 * E2*K1inv
# B2d = F2 - d2 * E1*K2inv

# right coideal generators
K = Monomial(1, ['K'])
B1c = Monomial(1, ['B1c'])
B2c = Monomial(1, ['B2c'])
B1d = Monomial(1, ['B1d'])
B2d = Monomial(1, ['B2d'])

A = Monomial(1, ['A'])

Al = Monomial(1, ['A'], [l])

def step1(Fk):
    '''Convert Fk to El and Bl, returns Bl, scalar, El'''
    if Fk.monomial[0] == 'F1':
        return B1d, d1, E2*K1inv
    else:
        return B2d, d2, E1*K2inv

def step2a(FI, Ek):
    if len(FI.monomial) == 0:
        return Ek

    F_last = FI[-1]
    F_rest = FI[:-1]

    if Ek.monomial[0] == 'E1':
        Eind = 1
    else:
        Eind = 2

    if F_last.monomial[0] == 'F1':
        Find = 1
    else:
        Find = 2

    if Find == 1 and Eind == 1:
        r = step2a(F_rest, Ek)
        main = q * step2a(F_rest, Ek) * F1
        if len(F_rest.monomial) > 0:
            rest = 1 / (q - q**(-1)) * F_rest * A**(-1) \
                - 1 / (q - q**(-1)) * F_rest *  K
        else:
            rest = 1 / (q - q**(-1)) * A**(-1) - 1 / (q - q**(-1)) * K
        return main + rest
    elif Find == 1 and Eind == 2:
        return q**(-2) * step2a(F_rest, Ek) * F1
    elif Find == 2 and Eind == 1:
        return q**(-2) * step2a(F_rest, Ek) * F2
    elif Find == 2 and Eind == 2:
        main = q * step2a(F_rest, Ek) * F2
        if len(F_rest.monomial) > 0:
            rest = 1 / (q - q**(-1)) * F_rest * (A**(-1) - K**(-1))
        else:
            rest = 1 / (q - q**(-1)) * (A**(-1) - K**(-1))
        return main + rest

def step2a(FI, Ek):
    if len(FI.monomial) == 0:
        return 1, 0

    F_last = FI[-1]
    F_rest = FI[:-1]

    if Ek.monomial[0] == 'E1':
        Eind = 1
    else:
        Eind = 2

    if F_last.monomial[0] == 'F1':
        Find = 1
    else:
        Find = 2

    if Find == 1 and Eind == 1:
        s, r = step2a(F_rest, Ek)
        if len(F_rest.monomial) > 0:
            rest = 1 / (q - q**(-1)) * F_rest * A**(-1) \
                - 1 / (q - q**(-1)) * F_rest *  K
        else:
            rest = 1 / (q - q**(-1)) * A**(-1) - 1 / (q - q**(-1)) * K
        if r != 0:
            return q*s, q*r + rest
        else:
            return q*s, rest
    elif Find == 1 and Eind == 2:
        s, r = step2a(F_rest, Ek)
        return q**(-2)*s, q**(-2)*r*F1
    elif Find == 2 and Eind == 1:
        s, r = step2a(F_rest, Ek)
        return q**(-2)*s, q**(-2)*r*F2
    elif Find == 2 and Eind == 2:
        s, r = step2a(F_rest, Ek)
        if len(F_rest.monomial) > 0:
            rest = 1 / (q - q**(-1)) * F_rest * (A**(-1) - K**(-1))
        else:
            rest = 1 / (q - q**(-1)) * (A**(-1) - K**(-1))
        if r != 0:
            return q*s, q*r + rest

def step2b(torus):
    # Commutation relation A^l between E_i K_i^{-1}
    return q**(torus.power[0])

def step3(Ek):
    if Ek.monomial[0] == 'E1':
        return 1/c2, F2, 1/c2 * B2c
    elif Ek.monomial[0] == 'E2':
        return 1/c1, F1, 1/c1 * B1c

def step4(torus):
    return q**(torus.power[0])

def convert(torus, F_seq):
    '''Apply one step of the q-radial algorithm, i.e. it maps

        A^l F_1 F_2 ... F_k |--> q^x A^l F_k F_1 ... F_{k-1} + ...

    Inputs:
        torus - Torus element A^l.
        F_seq - Monomial sequence F_1 F_2 ... F_k.

    Returns:
        scalar - Scalar term of A^l F_k F_1 ... F_{k-1}.
        main_mon - Monomial sequence A^l F_k F_1 ... F_{k-1}
        rest - Polynomial of extra terms generated by the algorithm.
    '''
    F_stable = F_seq[0:-1]
    F_last = F_seq[-1]

    # Step one, F_last to B and E
    s1_B, s1_scalar, s1_Ek = step1(F_last)

    # Step two a, commute between F_stable and E
    s2a_scalar, s2a_rest = step2a(F_stable, s1_Ek)

    # Step two b, commute EK and A^l
    s2b_scalar = step2b(torus)

    # Step three, replace EK with F - B
    s3_scalar, s3_F, s3_rest = step3(s1_Ek)

    # Step four, commute F and A^l
    s4_scalar = step4(torus)

    main_scalar = s1_scalar * s2a_scalar * s2b_scalar * s3_scalar * s4_scalar
    main_term = Al * s3_F * F_stable

    rest = torus * F_stable * s1_B
    if s2a_rest != 0:
        rest += s1_scalar * torus * s2a_rest
    if s3_rest != 0:
        rest += s1_scalar * s3_rest * torus * F_stable

    return main_scalar, main_term, rest


def std_form_A(M):
    scalar = M.scalar
    power = M.power
    monomial = M.monomial

    for i in range(len(monomial)-1, 0, -1):
        t1 = monomial[i]
        p1 = power[i]

        t2 = monomial[i-1]
        p2 = power[i-1]

        if t1 == 'A':
            if t2[0] == 'F':
                monomial[i] = t2
                power[i] = p2

                monomial[i-1] = t1
                power[i-1] = p1

                scalar *= q**(p1*p2)
            elif t2[0] == 'E':
                monomial[i] = t2
                power[i] = p2

                monomial[i-1] = t1
                power[i-1] = p1

                scalar *= q**(-p1)
            elif t2 == 'A':
                power[i-1] += p1
                del power[i]
                del monomial[i]

    return Monomial(scalar, monomial, power)
