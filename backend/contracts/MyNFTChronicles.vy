# @version ^0.3.7


from vyper.interfaces import ERC165
from vyper.interfaces import ERC721


interface ERC721Metadata:
    def name() -> String[64]: view

    def symbol() -> String[32]: view

    def tokenURI(_tokenId: uint256) -> String[128]: view


interface IERC5192:
    def locked(_tokenId: uint256) -> bool: view


interface Ownable:
    def owner() -> address: view
    
    def renounceOwnership(): nonpayable
    
    def transferOwnership(_newOwner: address): nonpayable


implements: ERC165
implements: ERC721
implements: ERC721Metadata
implements: IERC5192
implements: Ownable


# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
    def onERC721Received(
        _operator: address,
        _from: address,
        _tokenId: uint256,
        _data: Bytes[1024]
    ) -> bytes4: view


event Transfer:
    _from: address
    _to: address
    _tokenId: uint256


event Approval:
    _owner: address
    _approved: address
    _tokenId: uint256


event ApprovalForAll:
    _owner: address
    _operator: address
    _approved: bool


event OwnershipTransferred:
    _previousOwner: address
    _newOwner: address


event Locked:
    tokenId: uint256


event Unlocked:
    tokenId: uint256


ERC165_INTERFACE_ID: constant(bytes4) = 0x01ffc9a7
ERC721_INTERFACE_ID: constant(bytes4) = 0x80ac58cd
ERC721_METADATA_INTERFACE_ID: constant(bytes4) =0x5b5e139f
IERC5192_INTERFACE_ID: constant(bytes4) = 0xb45a3c0e


owner_of_nft: HashMap[uint256, address]
id_to_url: HashMap[uint256, String[64]]
token_count: HashMap[address, uint256]
number_of_tokens: uint256
approvals: HashMap[uint256, address]
operator: HashMap[address, HashMap[address, bool]]
owner: public(address)

name: public(String[64])
symbol: public(String[32])

is_locked: bool


@external
def __init__(_name: String[64], _symbol: String[32], _locked: bool):
    self.name = _name
    self.symbol = _symbol
    self.is_locked = _locked
    
    self._transfer_ownership(msg.sender)


@view
@external
def supportsInterface(interface_id: bytes4) -> bool:
    return interface_id in [
        ERC165_INTERFACE_ID,
        ERC721_INTERFACE_ID,
        ERC721_METADATA_INTERFACE_ID,
        IERC5192_INTERFACE_ID,
    ]


@external
def setup(_name: String[64], _symbol: String[32], _locked: bool, _owner: address):
    assert _owner != empty(address)
    assert self.owner == empty(address)
    
    self.name = _name
    self.symbol = _symbol
    self.is_locked = _locked
    
    self._transfer_ownership(_owner)


@view
@external
def balanceOf(_owner: address) -> uint256:
    assert _owner != empty(address), "Zero address"
    
    return self.token_count[_owner]


@view
@external
def ownerOf(_tokenId: uint256) -> address:
    owner: address = self.owner_of_nft[_tokenId]
    
    assert owner != empty(address), "Invalid token"
    
    return owner


@view
@external
def tokenURI(_tokenId: uint256) -> String[128]:
    assert self.owner_of_nft[_tokenId] != empty(address), "Invalid token"

    return self.id_to_url[_tokenId]


@view
@external
def locked(_tokenId: uint256) -> bool:
    assert self.owner_of_nft[_tokenId] != empty(address), "Invalid token"

    return self.is_locked


@view
@external
def getApproved(_tokenId: uint256) -> address:
    assert self.owner_of_nft[_tokenId] != empty(address), "Invalid token"

    return self.approvals[_tokenId]


@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    return self.operator[_owner][_operator]


@external
@payable
def transferFrom(_from: address, _to: address, _tokenId: uint256):
    self._transfer(_from, _to, _tokenId, msg.sender)


@external
@payable
def safeTransferFrom(_from: address, _to: address, _tokenId: uint256, _data: Bytes[1024]):
    self._transfer(_from, _to, _tokenId, msg.sender)
    
    if _to.is_contract:
        return_value: bytes4 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
        assert return_value == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes4)


@external
@payable
def approve(_approved: address, _tokenId: uint256):
    assert not self.is_locked, "Locked"
    
    sender: address = msg.sender
    owner: address = self.owner_of_nft[_tokenId]
    
    assert owner != empty(address), "Invalid token"
    assert sender == owner or self.operator[owner][sender], "Forbidden"
    assert _approved != owner, "Owner can't be approved"
    
    self.approvals[_tokenId] = _approved

    log Approval(owner, _approved, _tokenId)


@external
def setApprovalForAll(_operator: address, _approved: bool):
    assert not self.is_locked, "Locked"
    
    sender: address = msg.sender
    assert _operator != sender, "Owner"

    self.operator[sender][_operator] = _approved

    log ApprovalForAll(sender, _operator, _approved)


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
def mint(_url: String[64]):
    to: address = msg.sender
    assert to == self.owner, "Forbidden"
    token_id: uint256 = self.number_of_tokens
    
    self.owner_of_nft[token_id] = to
    self.id_to_url[token_id] = _url
    self.token_count[to] += 1
    self.number_of_tokens += 1
    
    log Transfer(empty(address), to, token_id)


@external
def burn(_token_id: uint256):
    owner: address = self.owner_of_nft[_token_id]
    assert owner != empty(address)

    sender: address = msg.sender
    assert sender in [self.owner_of_nft[_token_id], self.approvals[_token_id]] or self.operator[owner][sender], "Forbidden" 

    self.owner_of_nft[_token_id] = empty(address)
    self.token_count[owner] = unsafe_sub(self.token_count[owner], 1)

    self.approvals[_token_id] = empty(address)

    log Transfer(owner, empty(address), _token_id)


@internal
def _transfer(_from: address, _to: address, _token_id: uint256, _sender: address):
    assert not self.is_locked, "Locked"
    
    owner: address = self.owner_of_nft[_token_id]
    assert owner != empty(address), "Invalid token"
    assert owner == _from, "Forbidden"

    assert _sender in [self.owner_of_nft[_token_id], self.approvals[_token_id]] or self.operator[owner][_sender], "Forbidden" 

    self.owner_of_nft[_token_id] = _to
    self.token_count[_from] = unsafe_sub(self.token_count[_from], 1)
    self.token_count[_to] = unsafe_add(self.token_count[_to], 1)

    self.approvals[_token_id] = empty(address)

    log Transfer(owner, _to, _token_id)


@internal
def _transfer_ownership(_new_owner: address):
    old_owner: address = self.owner

    self.owner = _new_owner   
    
    log OwnershipTransferred(old_owner, _new_owner)
