rng_old = open("Normal.rng", "r")
rng_new =  open("Normal_new.rng", "w")

bpm_old = 149.78
bpm_new = 150.0
mult = bpm_new / bpm_old

for l in rng_old:
    line = l.split('; ')
    if len(line) > 2:
        new_line = ""
        new_line += line[0] + "; " + str(float(line[1]) * mult) + "; " + line[2]
        rng_new.write(new_line)
    else:
        rng_new.write(l)
    
