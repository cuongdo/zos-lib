pragma solidity ^0.4.24;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  function () payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   * 
   * NOTE(cuongdo): this is the core of the proxy
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      //
      // NOTE(cuongdo): docs for calldatacopy:
      // calldatacopy(t, f, s)
      //     copy s bytes from calldata at position f to mem at position t
      //
      // calldata == msg.data
      calldatacopy(0, 0, calldatasize)

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      //
      // NOTE(cuongdo): from docs:
      // call(g:u256, a:u256, v:u256, in:u256, insize:u256, out:u256, outsize:u256) -> r:u256	
      //     call contract at address a with input mem[in..(in+insize)) providing g gas and v wei 
      //     and output area mem[out..(out+outsize)) returning 0 on error (eg. out of gas) and 1 on success
      // callcode(g:u256, a:u256, v:u256, in:u256, insize:u256, out:u256, outsize:u256) -> r:u256
      //     identical to call but only use the code from a and stay in the context of the current contract otherwise
      // delegatecall(g:u256, a:u256, in:u256, insize:u256, out:u256, outsize:u256) -> r:u256
      //     identical to callcode, but also keep caller and callvalue
      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

      // Copy the returned data.
      // NOTE(cuongdo): returndatacopy has same parameters as calldatacopy above
      returndatacopy(0, 0, returndatasize)

      switch result
      // delegatecall returns 0 on error.
      // NOTE(cuongdo):
      // revert(p:u256, s:u256)
      //     end execution, revert state changes, return data mem[p..(p+s))
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal {
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}
