# @version ^0.3.0

from vyper.interfaces import ERC721

implements: ERC721

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

ERC165_INTERFACE_ID: constant(bytes4) = 0x01ffc9a7
ERC721_INTERFACE_ID: constant(bytes4) = 0x80ac58cd

owner_of_nft: HashMap[uint256, address]
id_to_url: HashMap[uint256, String[50]]
token_count: HashMap[address, uint256]
number_of_tokens: uint256
approvals: HashMap[uint256, address]

@external
def __init__():
    pass

@view
@external
def supportsInterface(interface_id: bytes4) -> bool:
    return interface_id in [
        ERC165_INTERFACE_ID,
        ERC721_INTERFACE_ID
    ]

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
def tokenURI(_tokenId: uint256) -> String[50]:
    assert self.owner_of_nft[_tokenId] != empty(address), "Invalid token"

    return self.id_to_url[_tokenId]

@view
@external
def getApproved(_tokenId: uint256) -> address:
    assert self.owner_of_nft[_tokenId] != empty(address), "Invalid token"

    return self.approvals[_tokenId]

@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    return True

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
    owner: address = self.owner_of_nft[_tokenId]
    
    assert owner != empty(address), "Invalid token"
    assert msg.sender == owner, "Forbidden"
    assert _approved != owner, "Owner can't be approved"
    
    self.approvals[_tokenId] = _approved

    log Approval(owner, _approved, _tokenId)

@external
def setApprovalForAll(_operator: address, _approved: bool):
    pass

@external
def mint(_url: String[50]):
    to: address = msg.sender
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
    assert self.owner_of_nft[_token_id] == sender or self.approvals[_token_id] == sender, "Forbidden" 

    self.owner_of_nft[_token_id] = empty(address)
    self.token_count[owner] = unsafe_sub(self.token_count[sender], 1)

    self.approvals[_token_id] = empty(address)

    log Transfer(owner, empty(address), _token_id)

@internal
def _transfer(_from: address, _to: address, _token_id: uint256, _sender: address):
    owner: address = self.owner_of_nft[_token_id]
    assert owner != empty(address)

    assert self.owner_of_nft[_token_id] == _sender or self.approvals[_token_id] == _sender, "Forbidden" 

    self.owner_of_nft[_token_id] = _to
    self.token_count[_from] = unsafe_sub(self.token_count[_from], 1)
    self.token_count[_to] = unsafe_add(self.token_count[_to], 1)

    self.approvals[_token_id] = empty(address)

    log Transfer(owner, _to, _token_id)