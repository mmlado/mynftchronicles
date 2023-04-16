import brownie
import pytest


from helper import (
    log_test,
    URI,
    ZERO_ADDRESS
)


PRICE = 10 ** 18

@pytest.fixture
def contract(MyNFTChronicles, accounts):
    yield MyNFTChronicles.deploy('', '', PRICE, {'from': accounts[0]})


def test_price(contract, accounts):
    assert contract.price() == PRICE


def test_set_price(contract, accounts):
    transaction = contract.setPrice(PRICE - 1)
    assert contract.price() == PRICE - 1

    log_test(transaction, 'PriceChanged', _previousPrice=PRICE, _newPrice=PRICE - 1)


def test_withdraw(contract, accounts):
    alice = accounts[0]

    balance = alice.balance()
    contract.mint(URI, {'from': alice, 'value': PRICE})
    assert alice.balance() == balance - PRICE

    contract.withdraw()
    assert alice.balance() == balance


def test_withdraw_no_fuds(contract, accounts):
    with brownie.reverts('No balance'):
        contract.withdraw()


def test_mint(contract, accounts):
    alice = accounts[0]
    assert (contract.balanceOf(alice) == 0)

    transaction = contract.mint(URI, {'from': alice, 'value': PRICE})

    log_test(transaction, 'Transfer', _from=ZERO_ADDRESS, _to=accounts[0], _tokenId=0)

    assert (contract.tokenURI(0) == URI)
    assert (contract.balanceOf(alice) == 1)
    assert (contract.ownerOf(0) == alice)


def test_no_value(contract, accounts):
    alice = accounts[0]

    with brownie.reverts('Not enough value'):
        contract.mint(URI, {'from': alice})


def test_insuficient_value(contract, accounts):
    alice = accounts[0]

    with brownie.reverts('Not enough value'):
        contract.mint(URI, {'from': alice, 'value': PRICE - 1})


def test_burn(contract, accounts):
    contract.mint(URI, {'value': PRICE})
    transaction = contract.burn(0)

    log_test(transaction, 'Transfer', _from=accounts[0], _to=ZERO_ADDRESS, _tokenId=0)

    assert (contract.balanceOf(accounts[0]) == 0)
    with brownie.reverts('Invalid token'):
        contract.tokenURI(0)


def test_burn_approve(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
    
    contract.mint(URI, {'from': alice, 'value' : PRICE})
    contract.approve(bob, 0, {'from': alice})
    transaction = contract.burn(0, {'from': bob})

    log_test(transaction, 'Transfer', _from=alice, _to=ZERO_ADDRESS, _tokenId=0)

    assert contract.balanceOf(alice) == 0

def test_burn_approval_for_all(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
 
    contract.mint(URI, {'from': alice, 'value' : PRICE})
    contract.setApprovalForAll(bob, True, {'from': alice})
    transaction = contract.burn(0, {'from': bob})

    log_test(transaction, 'Transfer', _from=accounts[0], _to=ZERO_ADDRESS, _tokenId=0)

    assert contract.balanceOf(alice) == 0


def test_burn_approval_for_all_forbidden(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
    charlie = accounts[2]
    
    contract.mint(URI, {'from': alice, 'value' : PRICE})
    contract.setApprovalForAll(bob, True, {'from': charlie})

    with brownie.reverts('Forbidden'):
        contract.burn(0, {'from': bob})


def test_burn_not_owner(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]

    contract.mint(URI, {'from': alice, 'value' : PRICE})

    with brownie.reverts('Forbidden'):
        contract.burn(0, {'from': bob})
