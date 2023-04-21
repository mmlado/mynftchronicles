from pprint import pprint
URI = 'ipfs://'
ZERO_ADDRESS = '0x' + '0' * 40


def log_test(transaction, name, **kwargs):
    assert (name in transaction.events)
    
    event = transaction.events[name]
    for key, value in kwargs.items():
        assert (event[key] == value)
