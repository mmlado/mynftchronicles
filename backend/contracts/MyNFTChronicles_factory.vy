# @version ^0.3.7


from vyper.interfaces import ERC165


interface MyNFTChronicles:
    def setup(_name: String[64], _symbol: String[32], _owner: address): nonpayable


interface Ownable:
    def owner() -> address: view
    
    def renounceOwnership(): nonpayable
    
    def transferOwnership(_newOwner: address): nonpayable


implements: Ownable


event NewMyNFTChronicles: 
    _contract: indexed(address)
    _owner: indexed(address)


event OwnershipTransferred:
    _previousOwner: address
    _newOwner: address


ERC721_INTERFACE_ID: constant(bytes4) = 0x80ac58cd


TEMPLATE: public(immutable(address))
owner: public(address)


@external
def __init__(_template: address):
    assert _template != empty(address)
    assert _template.is_contract
    assert ERC165(_template).supportsInterface(ERC721_INTERFACE_ID)
    
    TEMPLATE = _template
    
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
@payable
def mint(_name: String[64], _symbol: String[32]) -> address:
    owner: address = msg.sender

    contract: address = create_forwarder_to(TEMPLATE)
    MyNFTChronicles(contract).setup(_name, _symbol, owner)

    log NewMyNFTChronicles(contract, owner)    
    
    return contract


@internal
def _transfer_ownership(_new_owner: address):
    old_owner: address = self.owner

    self.owner = _new_owner   
    
    log OwnershipTransferred(old_owner, _new_owner)