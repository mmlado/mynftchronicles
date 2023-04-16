import brownie
import pytest


from helper import (
    log_test,
    URI,
    ZERO_ADDRESS
)


PRICE = 10 ** 18


@pytest.fixture
def contract(MyNFTChronicles_factory, accounts):
    yield MyNFTChronicles_factory.deploy(PRICE, {'from': accounts[0]})

def test_owner(contract, accounts):
    assert contract.owner() == accounts[0]


def test_renounce_ownership(contract, accounts):
    transaction = contract.renounceOwnership()

    assert contract.owner() == ZERO_ADDRESS

    log_test(transaction, 'OwnershipTransferred', _previousOwner=accounts[0], _newOwner=ZERO_ADDRESS)


def test_renounce_ownership_forbidden(contract, accounts):
    with brownie.reverts('Forbidden'):
        contract.renounceOwnership({'from': accounts[1]})


def test_transfer_ownership(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]

    transaction = contract.transferOwnership(bob)

    assert contract.owner() == bob

    log_test(transaction, 'OwnershipTransferred', _previousOwner=alice, _newOwner=bob)


def test_transfer_ownership_zero_address(contract, accounts):
    with brownie.reverts('Zero address'):
        contract.transferOwnership(ZERO_ADDRESS)


def test_transfer_ownership_forbidden(contract, accounts):
    bob = accounts[1]
    charlie = accounts[2]

    with brownie.reverts('Forbidden'):
        contract.transferOwnership(charlie, {'from': bob})


def test_transfer_ownership_already_owner(contract, accounts):
    with brownie.reverts('Already Owner'):
        contract.transferOwnership(accounts[0])


def test_price(contract, accounts):
    assert contract.price() == PRICE


def test_set_price(contract, accounts):
    transaction = contract.setPrice(PRICE - 1)
    assert contract.price() == PRICE - 1

    log_test(transaction, 'PriceChanged', _previousPrice=PRICE, _newPrice=PRICE - 1)


def test_withdraw(contract, accounts):
    alice = accounts[0]

    balance = alice.balance()
    contract.mint({'from': alice, 'value': PRICE})
    assert alice.balance() == balance - PRICE

    contract.withdraw()
    assert alice.balance() == balance


def test_withdraw_no_fuds(contract, accounts):
    with brownie.reverts('No balance'):
        contract.withdraw()


def test_insuficient_value(contract, accounts):
    alice = accounts[0]

    with brownie.reverts('Not enough value'):
        contract.mint({'from': alice, 'value': PRICE - 1})


def test_no_value(contract, accounts):
    alice = accounts[0]

    with brownie.reverts('Not enough value'):
        contract.mint({'from': alice})