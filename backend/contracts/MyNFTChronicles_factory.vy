# @version ^0.3.7


interface Ownable:
    def owner() -> address: view
    
    def renounceOwnership(): nonpayable
    
    def transferOwnership(_newOwner: address): nonpayable


implements: Ownable


event NewMyNFTChronicles: 
    contract: indexed(address)
    owner: indexed(address)


event OwnershipTransferred:
    _previousOwner: address
    _newOwner: address


event PriceChanged:
    _previousPrice: uint256
    _newPrice: uint256


price: public(uint256)
owner: public(address)


@external
def __init__(_price: uint256):
    self.price = _price

    self._transfer_ownership(msg.sender)


@external
def renounceOwnership():
    assert msg.sender == self.owner, "Forbidden"

    self._transfer_ownership(empty(address))
    

@external
def transferOwnership(_newOwner: address):
    assert _newOwner != empty(address), "Zero address" 
    assert msg.sender == self.owner, "Forbidden"
    assert _newOwner != self.owner, "Already Owner"
    
    self._transfer_ownership(_newOwner)


@external
def withdraw():
    current_balance: uint256 = self.balance
    assert current_balance > 0, "No balance"
    
    send(self.owner, current_balance)

@external
def setPrice(_price: uint256):
    assert msg.sender == self.owner, "Forbidden"
    
    old_price: uint256 = self.price

    self.price = _price

    log PriceChanged(old_price, _price)


@external
@payable
def mint() -> address:
    assert msg.value == self.price, "Not enough value"
    to: address = msg.sender
    
    # log Transfer(empty(address), to, token_id)
    return empty(address)


@internal
def _transfer_ownership(_new_owner: address):
    old_owner: address = self.owner

    self.owner = _new_owner   
    
    log OwnershipTransferred(old_owner, _new_owner)