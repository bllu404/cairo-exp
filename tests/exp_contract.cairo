%lang starknet

from contracts.exp import exp
from starkware.cairo.common.cairo_builtins import HashBuiltin

@view
func get_exp{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(x) -> (res):
    let (res) = exp(x)
    return (res)
end
