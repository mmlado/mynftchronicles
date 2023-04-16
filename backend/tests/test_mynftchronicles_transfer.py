import brownie
import pytest

from helper import (
    log_test,
    URI,
    ZERO_ADDRESS
)


@pytest.fixture
def contract(MyNFTChronicles, accounts):
    contract = MyNFTChronicles.deploy('', '', {'from': accounts[0]})

    contract.mint(URI, {'from': accounts[0]})
    
    yield contract


def test_transfer_from(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
    
    _test_transfer_from(contract.transferFrom, contract, alice, alice, bob)


def test_transfer_from_forbidden(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]

    _test_transfer_from_forbidden(contract.transferFrom, contract, alice, bob, alice)


def test_transfer_from_not_owner(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
    
    with brownie.reverts('Forbidden'):
        contract.transferFrom(bob, alice, 0, {'from': bob})


def test_transfer_from_invalid_token(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
    
    with brownie.reverts('Invalid token'):
        contract.transferFrom(alice, bob, 1, {'from': alice})


def test_safe_transfer_from(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]

    _test_transfer_from(contract.safeTransferFrom, contract, alice, alice, bob, '')


def test_safe_transfer_from_forbidden(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]

    _test_transfer_from_forbidden(contract.safeTransferFrom, contract, alice, bob, alice, '')


def test_transfer_from_approved(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
    charlie = accounts[2]

    contract.approve(charlie, 0, {'from': alice})

    _test_transfer_from(contract.transferFrom, contract, charlie, alice, bob)

    assert contract.getApproved(0) == ZERO_ADDRESS


def test_transfer_from_approved_forbidden(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
    charlie = accounts[2]

    contract.approve(charlie, 0, {'from': alice})

    _test_transfer_from_forbidden(contract.transferFrom, contract, charlie, bob, alice)
    

def test_transfer_from_approval_for_all(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
    charlie = accounts[2]

    contract.setApprovalForAll(charlie, True, {'from': alice})

    _test_transfer_from(contract.transferFrom, contract, charlie, alice, bob)


def test_transfer_from_approval_for_all_forbidden(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
    charlie = accounts[2]

    contract.setApprovalForAll(charlie, False, {'from': alice})

    _test_transfer_from_forbidden(contract.transferFrom, contract, charlie, bob, alice)

    assert contract.ownerOf(0) == alice


def _test_transfer_from(function, contract, sender, from_address, to_address, *args):
    from_balance = contract.balanceOf(from_address)
    to_balance = contract.balanceOf(to_address)

    transaction = function(from_address, to_address, 0, *args, {'from': sender})

    assert (contract.balanceOf(from_address) == from_balance - 1)
    assert (contract.balanceOf(to_address) == to_balance + 1)
    assert (contract.ownerOf(0) == to_address)

    log_test(transaction, 'Transfer', _from=from_address, _to=to_address, _tokenId=0)


def _test_transfer_from_forbidden(function, contract, sender, from_account, to_account, *args):
    with brownie.reverts('Forbidden'):
        function(from_account, to_account, 0, *args, {'from': sender})
