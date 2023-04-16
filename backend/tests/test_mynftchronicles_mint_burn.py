import brownie
import pytest


from helper import (
    log_test,
    URI,
    ZERO_ADDRESS
)


@pytest.fixture
def contract(MyNFTChronicles, accounts):
    yield MyNFTChronicles.deploy('', '', {'from': accounts[0]})


def test_mint(contract, accounts):
    alice = accounts[0]
    assert (contract.balanceOf(alice) == 0)

    transaction = contract.mint(URI, {'from': alice})

    log_test(transaction, 'Transfer', _from=ZERO_ADDRESS, _to=accounts[0], _tokenId=0)

    assert (contract.tokenURI(0) == URI)
    assert (contract.balanceOf(alice) == 1)
    assert (contract.ownerOf(0) == alice)


def test_burn(contract, accounts):
    contract.mint(URI)
    transaction = contract.burn(0)

    log_test(transaction, 'Transfer', _from=accounts[0], _to=ZERO_ADDRESS, _tokenId=0)

    assert (contract.balanceOf(accounts[0]) == 0)
    with brownie.reverts('Invalid token'):
        contract.tokenURI(0)


def test_burn_approve(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
    
    contract.mint(URI, {'from': alice})
    contract.approve(bob, 0, {'from': alice})
    transaction = contract.burn(0, {'from': bob})

    log_test(transaction, 'Transfer', _from=alice, _to=ZERO_ADDRESS, _tokenId=0)

    assert contract.balanceOf(alice) == 0

def test_burn_approval_for_all(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
 
    contract.mint(URI, {'from': alice})
    contract.setApprovalForAll(bob, True, {'from': alice})
    transaction = contract.burn(0, {'from': bob})

    log_test(transaction, 'Transfer', _from=accounts[0], _to=ZERO_ADDRESS, _tokenId=0)

    assert contract.balanceOf(alice) == 0


def test_burn_approval_for_all_forbidden(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
    charlie = accounts[2]
    
    contract.mint(URI, {'from': alice})
    contract.setApprovalForAll(bob, True, {'from': charlie})

    with brownie.reverts('Forbidden'):
        contract.burn(0, {'from': bob})


def test_burn_not_owner(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]

    contract.mint(URI, {'from': alice})

    with brownie.reverts('Forbidden'):
        contract.burn(0, {'from': bob})
