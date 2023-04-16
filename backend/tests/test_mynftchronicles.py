import brownie
import pytest

from helper import (
    ZERO_ADDRESS
)

ERC721_INTERFACE = 0x80ac58cd
NAME = 'Test'
SYMBOL = 'TEST'


@pytest.fixture
def contract(MyNFTChronicles, accounts):
    yield MyNFTChronicles.deploy(NAME, SYMBOL, {'from': accounts[0]})


def test_erc721_interface(contract, accounts):
    assert contract.supportsInterface(ERC721_INTERFACE)


def test_balance_of(contract, accounts):
    with brownie.reverts('Zero address'):
        contract.balanceOf(ZERO_ADDRESS)

    assert contract.balanceOf(accounts[0]) == 0


def test_name(contract, accounts):
    assert contract.name() == NAME


def test_symbol(contract, accounts):
    assert contract.symbol() == SYMBOL


def test_token_uri_invalid_token(contract, accounts):
    with brownie.reverts('Invalid token'):
        contract.tokenURI(0)


def test_set_approval_for_all(contract, accounts):
    alice = accounts[0]
    bob = accounts[1]
    
    assert not contract.isApprovedForAll(alice, bob)
    contract.setApprovalForAll(bob, True, {'from': alice})
    assert contract.isApprovedForAll(alice, bob)

    contract.setApprovalForAll(bob, False, {'from': alice})
    assert not contract.isApprovedForAll(alice, bob)
