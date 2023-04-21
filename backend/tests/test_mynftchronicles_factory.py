import brownie
import pytest
from pprint import pprint

from helper import (
    log_test,
    ZERO_ADDRESS
)


@pytest.fixture
def contract(MyNFTChronicles_factory, MyNFTChronicles, accounts):
    chronicles = MyNFTChronicles.deploy('', '', {'from': accounts[0]})
    yield MyNFTChronicles_factory.deploy(chronicles, {'from': accounts[0]})


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


def test_withdraw(contract, accounts):
    alice = accounts[0]

    balance = alice.balance()
    contract.mint('', '', {'from': alice, 'value': 1})
    assert alice.balance() == balance - 1

    contract.withdraw()
    assert alice.balance() == balance


def test_withdraw_no_fuds(contract, accounts):
    with brownie.reverts('No balance'):
        contract.withdraw()


def test_mint(contract, accounts):
    alice = accounts[0]

    transaction = contract.mint('', '', {'from': alice})

    log_test(transaction, 'NewMyNFTChronicles', _contract=transaction.return_value, _owner=alice)
