# Ported to Cairo from https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/solidity-utils/contracts/math/LogExpMath.sol
%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import unsigned_div_rem, assert_le, assert_lt
from starkware.cairo.common.math_cmp import is_le

# Constants
const ONE_18 = 10 ** 18

# Higher precision numbers are used internally
const ONE_20 = 10 ** 20

# The domain of natural exponentiation is bound by the word size and number of decimals used.
#
# Because internally the result will be stored using 20 decimals, the largest possible result is
# (2^125 - 1) / 10^20, which makes the largest exponent ln((2^125 - 1) / 10^20) ~= 40.5961.
# The smallest possible result is 10^(-18), which makes largest negative argument
# ln(10^(-18)) = -41.446531673892822312.
# However, since negative exponents are converted to positive exponents by `exp`, and
# since abs(-41.446...) > abs(40.5961), the lower bound is actually `-MAX_NATURAL_EXPONENT`
const MAX_NATURAL_EXPONENT = 40 * 10 ** 18

# 18 decimal constants
const x0 = 128000000000000000000  # 2ˆ7
const a0 = 38877084059945950922200000000000000000000000000000000000  # eˆ(x0) (no decimals)
const x1 = 64000000000000000000  # 2ˆ6
const a1 = 6235149080811616882910000000  # eˆ(x1) (no decimals)

# 20 decimal constants
const x2 = 3200000000000000000000  # 2ˆ5
const a2 = 7896296018268069516100000000000000  # eˆ(x2)
const x3 = 1600000000000000000000  # / 2ˆ4
const a3 = 888611052050787263676000000  # 00; // eˆ(x3)
const x4 = 800000000000000000000  # 2ˆ3
const a4 = 298095798704172827474000  # eˆ(x4)
const x5 = 400000000000000000000  # 2ˆ2
const a5 = 5459815003314423907810  # eˆ(x5)
const x6 = 200000000000000000000  # 2ˆ1
const a6 = 738905609893065022723  # eˆ(x6)
const x7 = 100000000000000000000  # 2ˆ0
const a7 = 271828182845904523536  # eˆ(x7)
const x8 = 50000000000000000000  # 2ˆ-1
const a8 = 164872127070012814685  # eˆ(x8)
const x9 = 25000000000000000000  # 2ˆ-2
const a9 = 128402541668774148407  # eˆ(x9)
const x10 = 12500000000000000000  # 2ˆ-3
const a10 = 113314845306682631683  # eˆ(x10)
const x11 = 6250000000000000000  # 2ˆ-4
const a11 = 106449445891785942956  # eˆ(x11)

# Natural exponential function e^x, with signed 18 decimal fixed point exponent

func exp{range_check_ptr}(x) -> (res):
    alloc_locals
    # Checking that `x` is in the acceptable range for `exp`
    assert_le(x, MAX_NATURAL_EXPONENT)

    # Only positive exponents are handled. e^(-x) is computed as 1 / e^x.
    let (x_lt_zero) = is_le(x, -1)
    if x_lt_zero == TRUE:
        let (inverted_exp) = exp(-x)
        let (exp_x, _) = unsigned_div_rem(ONE_18 * ONE_18, inverted_exp)
        return (exp_x)
    end

    let (x_geq_x0) = is_le(x0, x)
    if x_geq_x0 == TRUE:
        tempvar x = x - x0
        tempvar firstAN = a0
    else:
        let (x_geq_x1) = is_le(x1, x)
        if x_geq_x1 == TRUE:
            tempvar x = x - x1
            tempvar firstAN = a1
        else:
            tempvar x = x
            tempvar firstAN = 1
        end
    end

    local firstAN = firstAN

    tempvar x = x * 100  # Scaling x from an 18 decimal number to a 20 decimal number to enhance precision

    # `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
    # one. Recall that fixed point multiplication requires dividing by ONE_20.
    let product = ONE_20

    let (x_geq_x2) = is_le(x2, x)

    if x_geq_x2 == TRUE:
        let (product, _) = unsigned_div_rem(product * a2, ONE_20)
        tempvar product = product
        tempvar x = x - x2
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar product = product
        tempvar x = x
        tempvar range_check_ptr = range_check_ptr
    end

    local product = product
    local x = x

    let (x_geq_x3) = is_le(x3, x)

    if x_geq_x3 == TRUE:
        let (product, _) = unsigned_div_rem(product * a3, ONE_20)
        tempvar product = product
        tempvar x = x - x3
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar product = product
        tempvar x = x
        tempvar range_check_ptr = range_check_ptr
    end

    local product = product
    local x = x
    let (x_geq_x4) = is_le(x4, x)

    if x_geq_x4 == TRUE:
        let (product, _) = unsigned_div_rem(product * a4, ONE_20)
        tempvar product = product
        tempvar x = x - x4
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar product = product
        tempvar x = x
        tempvar range_check_ptr = range_check_ptr
    end

    local product = product
    local x = x
    let (x_geq_x5) = is_le(x5, x)

    if x_geq_x5 == TRUE:
        let (product, _) = unsigned_div_rem(product * a5, ONE_20)
        tempvar product = product
        tempvar x = x - x5
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar product = product
        tempvar x = x
        tempvar range_check_ptr = range_check_ptr
    end

    local product = product
    local x = x
    let (x_geq_x6) = is_le(x6, x)

    if x_geq_x6 == TRUE:
        let (product, _) = unsigned_div_rem(product * a6, ONE_20)
        tempvar product = product
        tempvar x = x - x6
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar product = product
        tempvar x = x
        tempvar range_check_ptr = range_check_ptr
    end

    local product = product
    local x = x
    let (x_geq_x7) = is_le(x7, x)

    if x_geq_x7 == TRUE:
        let (product, _) = unsigned_div_rem(product * a7, ONE_20)
        tempvar product = product
        tempvar x = x - x7
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar product = product
        tempvar x = x
        tempvar range_check_ptr = range_check_ptr
    end

    local product = product
    local x = x
    let (x_geq_x8) = is_le(x8, x)

    if x_geq_x8 == TRUE:
        let (product, _) = unsigned_div_rem(product * a8, ONE_20)
        tempvar product = product
        tempvar x = x - x8
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar product = product
        tempvar x = x
        tempvar range_check_ptr = range_check_ptr
    end

    local product = product
    local x = x
    let (x_geq_x9) = is_le(x9, x)

    if x_geq_x9 == TRUE:
        let (product, _) = unsigned_div_rem(product * a9, ONE_20)
        tempvar product = product
        tempvar x = x - x9
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar product = product
        tempvar x = x
        tempvar range_check_ptr = range_check_ptr
    end

    # x10 and x11 are unnecessary since the precision is high enough already

    # Next up is the Taylor series

    # First term
    let series_sum = ONE_20

    # Second term
    let term = x
    let series_sum = series_sum + term

    # Third term
    let term = term * x
    let (term, _) = unsigned_div_rem(term, ONE_20 * 2)
    let series_sum = series_sum + term

    let term = term * x
    let (term, _) = unsigned_div_rem(term, ONE_20 * 3)
    let series_sum = series_sum + term

    let term = term * x
    let (term, _) = unsigned_div_rem(term, ONE_20 * 4)
    let series_sum = series_sum + term

    let term = term * x
    let (term, _) = unsigned_div_rem(term, ONE_20 * 5)
    let series_sum = series_sum + term

    let term = term * x
    let (term, _) = unsigned_div_rem(term, ONE_20 * 6)
    let series_sum = series_sum + term

    let term = term * x
    let (term, _) = unsigned_div_rem(term, ONE_20 * 7)
    let series_sum = series_sum + term

    let term = term * x
    let (term, _) = unsigned_div_rem(term, ONE_20 * 8)
    let series_sum = series_sum + term

    let term = term * x
    let (term, _) = unsigned_div_rem(term, ONE_20 * 9)
    let series_sum = series_sum + term

    let term = term * x
    let (term, _) = unsigned_div_rem(term, ONE_20 * 10)
    let series_sum = series_sum + term

    let term = term * x
    let (term, _) = unsigned_div_rem(term, ONE_20 * 11)
    let series_sum = series_sum + term

    let term = term * x
    let (term, _) = unsigned_div_rem(term, ONE_20 * 12)
    let series_sum = series_sum + term

    let (product_times_series_sum, _) = unsigned_div_rem(product * series_sum, ONE_20)
    let (res, _) = unsigned_div_rem(product_times_series_sum * firstAN, 100)

    return (res)
end
