# @version ^0.3.7
# @dev Implementation of ERC-721 non-fungible token standard with ERC5192 for Minimal Soulbound NFTs
# @author Mladen Milankovic (@mmlado)

from vyper.interfaces import ERC165
from vyper.interfaces import ERC721


# Interface for metadata
interface ERC721Metadata:
    def name() -> String[64]: view

    def symbol() -> String[32]: view

    def tokenURI(_tokenId: uint256) -> String[128]: view

# Interface for Minimal Soulbound Token
interface IERC5192:
    def locked(_tokenId: uint256) -> bool: view


# Interface for the contract to be ownable by an address
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


# @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
#      created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
#      number of NFTs may be created and assigned without emitting Transfer. At the time of any
#      transfer, the approved address for that NFT (if any) is reset to none.
# @param _from Sender of NFT (if address is zero address it indicates token creation).
# @param _to Receiver of NFT (if address is zero address it indicates token destruction).
# @param _tokenId The NFT that got transfered.
event Transfer:
    _from: address
    _to: address
    _tokenId: uint256


# @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
#      address indicates there is no approved address. When a Transfer event emits, this also
#      indicates that the approved address for that NFT (if any) is reset to none.
# @param _owner Owner of NFT.
# @param _approved Address that we are approving.
# @param _tokenId NFT which we are approving.
event Approval:
    _owner: address
    _approved: address
    _tokenId: uint256


# @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
#      all NFTs of the owner.
# @param _owner Owner of NFT.
# @param _operator Address to which we are setting operator rights.
# @param _approved Status of operator rights(true if operator rights are given and false if
#        revoked).
event ApprovalForAll:
    _owner: address
    _operator: address
    _approved: bool


# @dev This emits when the owner of the contract is changed. It also emits during the contract creation
# @param _previousOwner The owner that was removed from the contract.
# @param _newOwner The owner that the contract ownership was transfered to. I.e. after this event the 
#        current owner
event OwnershipTransferred:
    _previousOwner: address
    _newOwner: address

# @dev Emitted when the locking status is changed to locked.
#      If a token is minted and the status is locked, this event should be emitted.
# @param tokenId The identifier for a token.
event Locked:
    tokenId: uint256


# @dev Emitted when the locking status is changed to unlocked.
#      If a token is minted and the status is unlocked, this event should be emitted.
# @param tokenId The identifier for a token.
event Unlocked:
    tokenId: uint256


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

# @dev Static list of supported ERC165 interface ids
SUPPORTED_INTERFACES: constant(bytes4[4]) = [
    # ERC165 interface ID of ERC165
    0x01ffc9a7,
    # ERC165 interface ID of ERC721
    0x80ac58cd,
    # ERC165 interface ID of ERC721Metadata
    0x5b5e139f,
    # ERC165 interface ID of IERC5192
    0xb45a3c0e
]



@external
def __init__(_name: String[64], _symbol: String[32], _locked: bool):
    """
    @dev Contract constructor.
    @param _name Name of the token
    @param _symbol Symbol of the token
    @param _locked Whether the tokens should be locked or transferable
    """
    self.name = _name
    self.symbol = _symbol
    self.is_locked = _locked
    
    self._transfer_ownership(msg.sender)


@view
@external
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Interface identification is specified in ERC-165.
    @param interface_id Id of the interface
    """
    return interface_id SUPPORTED_INTERFACES


@external
def setup(_name: String[64], _symbol: String[32], _locked: bool, _owner: address):
    assert _owner != empty(address)
    assert self.owner == empty(address)
    
    self.name = _name
    self.symbol = _symbol
    self.is_locked = _locked
    
    self._transfer_ownership(_owner)


### VIEW FUNCTIONS ###

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
