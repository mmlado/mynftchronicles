import pytest


@pytest.fixture
def nftopia_contract(NFTopia, accounts):
    # deploy the contract with the initial value as a constructor argument
    yield NFTopia.deploy({'from': accounts[0]})

def test_owner(nftopia_contract, accounts):
    assert nftopia_contract.isOwner()