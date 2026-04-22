# Description: Uses iterative design equations for a pyramidal horn
# to produce antenna dimensions for a desired gain
# Author: Spandan Bharadwaj
# Date: 4/3/26

# p_e=p_h must be less than 27cm which is the maximum z height of the printer
import numpy as np

# Desired gain
Gdb=15
G=10**(Gdb/10)

# Desired frequency in GHz
f = 2.40e9
lam = 3e8/f

# Waveguide dimensions in meters
# WR 340 2.20 to 3.30 GHz 
a = 0.08636
b = 0.04318

chi = G/(2*np.pi*np.sqrt(2*np.pi))
diff = 1e9
# Stopping condition
delta_chi = 0.00001

while abs(diff)>0.00001:
    lhs = (np.sqrt(2*chi)-b/lam)**2*(2*chi-1)
    rhs = (G/(2*np.pi)*np.sqrt(3/(2*np.pi))*1/np.sqrt(chi)-a/lam)**2*(G**2/(6*np.pi**3)*1/chi-1)
    diff = abs(lhs-rhs)
    
    check_chi = chi*(1+delta_chi)
    lhs = (np.sqrt(2*check_chi)-b/lam)**2*(2*check_chi-1)
    rhs = (G/(2*np.pi)*np.sqrt(3/(2*np.pi))*1/np.sqrt(check_chi)-a/lam)**2*(G**2/(6*np.pi**3)*1/check_chi-1)
    new_diff = abs(lhs-rhs)
    
    if new_diff > diff:
        chi = chi*(1-delta_chi)
    else:
        chi = check_chi
        diff = new_diff
        
a_1 = G/(2*np.pi)*np.sqrt(3/(2*np.pi*chi))*lam
b_1 = np.sqrt(2*chi)*lam
rho_e = chi*lam
rho_h = G**2/(8*np.pi**3)*(1/chi)*lam
p_e = (b_1-b)*np.sqrt((rho_e/b_1)**2-1/4)
p_h = (a_1-a)*np.sqrt((rho_h/a_1)**2-1/4)

print('p_e = ', p_e)
print('p_h = ', p_h)
print('a_1 = ', a_1)
print('b_1 = ', b_1)   