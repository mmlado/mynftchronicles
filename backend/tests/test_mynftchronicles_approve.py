import brownie
import pytest

from helper import (
    log_test,
    URI
)


@pytest.fixture
def contract(MyNFTChronicles, accounts):
    yield MyNFTChronicles.deploy('', '', 0, {'from': accounts[0]})


def test_get_approved_invalid_token(contract, accounts):
    with brownie.reverts('Invalid token'):
        contract.getApproved(0)


def test_approve(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]

    contract.mint(URI, {'from': alice})

    transaction = contract.approve(bob, 0, {'from': alice})

    log_test(transaction, 'Approval', _owner=alice, _approved=bob, _tokenId=0)

    assert contract.getApproved(0) == bob


def test_approve_invalid_token(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]

    with brownie.reverts('Invalid token'):
        contract.approve(bob, 0, {'from': alice})


def test_approve_approve_for_all(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
    charlie = accounts[2]

    contract.setApprovalForAll(charlie, True, {'from': alice})

    contract.mint(URI, {'from': alice})

    transaction = contract.approve(bob, 0, {'from': charlie})

    log_test(transaction, 'Approval', _owner=alice, _approved=bob, _tokenId=0)
    assert contract.getApproved(0) == bob


def test_approve_not_owner(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
    charlie = accounts[2]

    contract.mint(URI, {'from': alice})

    with brownie.reverts('Forbidden'):
        contract.approve(charlie, 0, {'from': bob})


def test_approve_owner_approved(contract, accounts):
    alice = accounts[0]

    contract.mint(URI, {'from': alice})

    with brownie.reverts('Owner can\'t be approved'):
        contract.approve(alice, 0, {'from': alice})
