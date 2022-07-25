import os
import asyncio
from decimal import Decimal
from math import exp
from typing import Union 

import pytest
from hypothesis import assume, example, given, settings
from hypothesis import strategies as st

from starkware.starkware_utils.error_handling import StarkException
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.services.api.contract_class import ContractClass
from starkware.starknet.compiler.compile import compile_starknet_files


# Constants 
ERROR_MARGIN = Decimal("0.000000001") # Default error margin for fixed point calculations
PRIME = 2**251 + 17 * 2**192 + 1 # Cairo prime
WAD_SCALE = 10 ** 18

# Utility functions 

def assert_equalish(a: Decimal, b: Decimal, error=ERROR_MARGIN):
    assert abs(a - b) <= error

def from_wad(n: int) -> Decimal:
    return Decimal(n) / WAD_SCALE

def to_wad(n: Union[int, float, Decimal]) -> int:
    return int(n * WAD_SCALE)

def signed_int_to_felt(a: int) -> int:
    """Takes in integer value, returns input if positive, otherwise return PRIME + input"""
    if a >= 0:
        return a
    return PRIME + a


def here() -> str:
    return os.path.abspath(os.path.dirname(__file__))

def contract_path(rel_contract_path: str) -> str:
    return os.path.join(here(), "..", rel_contract_path)

def compile_contract(rel_contract_path: str) -> ContractClass:
    contract_src = contract_path(rel_contract_path)
    tld = os.path.join(here(), "..")
    return compile_starknet_files(
        [contract_src],
        debug_info=True,
        disable_hint_validation=True,
        cairo_path=[tld, os.path.join(tld, "contracts", "lib")],
    )

# Python's exponential function starts to diverge significantly from the Cairo implementation
# for exponents larger than around 25-26.
# Interestingly enough, when checking against high-precision online calculators,
# it seems that the Cairo version is actually significantly
# more precise than the python version for large numbers, whereas they tend to
# be extremely close to each other for smaller numbers.
st_non_divergent_range = st.integers(min_value=-to_wad(40), max_value=to_wad(25))

st_invalid_range1 = st.integers(min_value=-(2**125), max_value=-to_wad(40) - 1)
st_invalid_range2 = st.integers(min_value=to_wad(40) + 1, max_value=2**125)


@pytest.fixture(scope="session")
def event_loop():
    return asyncio.new_event_loop()


@pytest.fixture(scope="session")
async def deploy_test_contract():
    starknet = await Starknet.empty()
    test_contract = compile_contract("tests/exp_contract.cairo")

    contract = await starknet.deploy(contract_class=test_contract)

    return contract


@settings(max_examples=100, deadline=None)
@given(val=st_non_divergent_range)
@example(val=to_wad(25))
@example(val=-to_wad(40))
@pytest.mark.asyncio
async def test_exp_pass(deploy_test_contract, val):
    contract = deploy_test_contract

    # Python's exponential function starts to diverge significantly from the Cairo implementation
    # for exponents larger than around 25-26.
    # Interestingly enough, when checking against high-precision online calculators,
    # it seems that the Cairo version is actually significantly
    # more precise than the python version for large numbers, whereas they tend to
    # be extremely close to each other for smaller numbers.

    tx = await contract.get_exp(signed_int_to_felt(val)).invoke()

    result = Decimal(from_wad(tx.result.res))
    expected_result = Decimal(exp(from_wad(val)))
    assert_equalish(result, expected_result, Decimal("0.0001"))


@settings(max_examples=100, deadline=None)
@given(val_r1=st_invalid_range1, val_r2=st_invalid_range2)
@example(val_r1=-to_wad(40) - 1, val_r2=to_wad(40) + 1)
@pytest.mark.asyncio
async def test_exp_fail(deploy_test_contract, val_r1, val_r2):
    contract = deploy_test_contract

    with pytest.raises(StarkException):
        await contract.get_exp(signed_int_to_felt(val_r1)).invoke()

    with pytest.raises(StarkException):
        await contract.get_exp(signed_int_to_felt(val_r2)).invoke()


# This tests that exp(-x) = 1/exp(x)
@settings(max_examples=100, deadline=None)
@given(val=st_non_divergent_range)
@example(val=to_wad(25))
@example(val=-to_wad(40))
@pytest.mark.asyncio
async def test_exp_inversions(deploy_test_contract, val):
    contract = deploy_test_contract

    result = Decimal(from_wad((await contract.get_exp(signed_int_to_felt(val)).invoke()).result.res))
    inverse_result = Decimal(from_wad((await contract.get_exp(signed_int_to_felt(-val)).invoke()).result.res))

    # Precision starts getting pretty bad with all these multiplications and divisions
    assert_equalish(result * inverse_result, Decimal(1), Decimal("0.06"))


# This tests that exp(x+y) = exp(x)*exp(y)
@settings(max_examples=100, deadline=None)
@given(val1=st_non_divergent_range, val2=st_non_divergent_range)
@pytest.mark.asyncio
async def test_exp_sum(deploy_test_contract, val1, val2):

    # Skip if the sum of the two values is greater than 40 or less than -40 (the maximum and minimum possible values respectively)
    assume(val1 + val2 <= to_wad(40) and val1 + val2 >= -to_wad(40))

    contract = deploy_test_contract

    result1 = Decimal(from_wad((await contract.get_exp(signed_int_to_felt(val1)).invoke()).result.res))
    result2 = Decimal(from_wad((await contract.get_exp(signed_int_to_felt(val2)).invoke()).result.res))
    result_sum = Decimal(from_wad((await contract.get_exp(signed_int_to_felt(val1 + val2)).invoke()).result.res))

    assert_equalish(result1 * result2, result_sum, Decimal("0.01"))
