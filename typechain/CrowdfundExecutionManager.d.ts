/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import {
  ethers,
  EventFilter,
  Signer,
  BigNumber,
  BigNumberish,
  PopulatedTransaction,
  BaseContract,
  ContractTransaction,
  Overrides,
  CallOverrides,
} from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { Listener, Provider } from "@ethersproject/providers";
import { FunctionFragment, EventFragment, Result } from "@ethersproject/abi";
import type { TypedEventFilter, TypedEvent, TypedListener } from "./common";

interface CrowdfundExecutionManagerInterface extends ethers.utils.Interface {
  functions: {
    "addExecutionHandler(address,address)": FunctionFragment;
    "collectERC20(address)": FunctionFragment;
    "collectFees()": FunctionFragment;
    "executionHandlers(address)": FunctionFragment;
    "manageExecution(address,address,address,address,uint256,bytes)": FunctionFragment;
    "owner()": FunctionFragment;
    "setOwner(address)": FunctionFragment;
    "updateExecutionHandler(address,address)": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "addExecutionHandler",
    values: [string, string]
  ): string;
  encodeFunctionData(
    functionFragment: "collectERC20",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "collectFees",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "executionHandlers",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "manageExecution",
    values: [string, string, string, string, BigNumberish, BytesLike]
  ): string;
  encodeFunctionData(functionFragment: "owner", values?: undefined): string;
  encodeFunctionData(functionFragment: "setOwner", values: [string]): string;
  encodeFunctionData(
    functionFragment: "updateExecutionHandler",
    values: [string, string]
  ): string;

  decodeFunctionResult(
    functionFragment: "addExecutionHandler",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "collectERC20",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "collectFees",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "executionHandlers",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "manageExecution",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "owner", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "setOwner", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "updateExecutionHandler",
    data: BytesLike
  ): Result;

  events: {
    "ExecutionHandlerAdded(address,address)": EventFragment;
    "ExecutionHandlerUpdated(address,address)": EventFragment;
    "OwnerUpdated(address,address)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "ExecutionHandlerAdded"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "ExecutionHandlerUpdated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "OwnerUpdated"): EventFragment;
}

export type ExecutionHandlerAddedEvent = TypedEvent<
  [string, string] & { newHandledAddress: string; executionHandler: string }
>;

export type ExecutionHandlerUpdatedEvent = TypedEvent<
  [string, string] & { handledAddress: string; newExecutionHandler: string }
>;

export type OwnerUpdatedEvent = TypedEvent<
  [string, string] & { user: string; newOwner: string }
>;

export class CrowdfundExecutionManager extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  listeners<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter?: TypedEventFilter<EventArgsArray, EventArgsObject>
  ): Array<TypedListener<EventArgsArray, EventArgsObject>>;
  off<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  on<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  once<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  removeListener<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  removeAllListeners<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>
  ): this;

  listeners(eventName?: string): Array<Listener>;
  off(eventName: string, listener: Listener): this;
  on(eventName: string, listener: Listener): this;
  once(eventName: string, listener: Listener): this;
  removeListener(eventName: string, listener: Listener): this;
  removeAllListeners(eventName?: string): this;

  queryFilter<EventArgsArray extends Array<any>, EventArgsObject>(
    event: TypedEventFilter<EventArgsArray, EventArgsObject>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEvent<EventArgsArray & EventArgsObject>>>;

  interface: CrowdfundExecutionManagerInterface;

  functions: {
    addExecutionHandler(
      newHandledAddress: string,
      executionHandler: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    collectERC20(
      erc20: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    collectFees(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    executionHandlers(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<[string]>;

    manageExecution(
      crowdfundContract: string,
      targetContract: string,
      assetContract: string,
      forumGroup: string,
      tokenId: BigNumberish,
      payload: BytesLike,
      overrides?: CallOverrides
    ): Promise<[BigNumber, string]>;

    owner(overrides?: CallOverrides): Promise<[string]>;

    setOwner(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    updateExecutionHandler(
      handledAddress: string,
      newExecutionHandler: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;
  };

  addExecutionHandler(
    newHandledAddress: string,
    executionHandler: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  collectERC20(
    erc20: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  collectFees(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  executionHandlers(arg0: string, overrides?: CallOverrides): Promise<string>;

  manageExecution(
    crowdfundContract: string,
    targetContract: string,
    assetContract: string,
    forumGroup: string,
    tokenId: BigNumberish,
    payload: BytesLike,
    overrides?: CallOverrides
  ): Promise<[BigNumber, string]>;

  owner(overrides?: CallOverrides): Promise<string>;

  setOwner(
    newOwner: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  updateExecutionHandler(
    handledAddress: string,
    newExecutionHandler: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    addExecutionHandler(
      newHandledAddress: string,
      executionHandler: string,
      overrides?: CallOverrides
    ): Promise<void>;

    collectERC20(erc20: string, overrides?: CallOverrides): Promise<void>;

    collectFees(overrides?: CallOverrides): Promise<void>;

    executionHandlers(arg0: string, overrides?: CallOverrides): Promise<string>;

    manageExecution(
      crowdfundContract: string,
      targetContract: string,
      assetContract: string,
      forumGroup: string,
      tokenId: BigNumberish,
      payload: BytesLike,
      overrides?: CallOverrides
    ): Promise<[BigNumber, string]>;

    owner(overrides?: CallOverrides): Promise<string>;

    setOwner(newOwner: string, overrides?: CallOverrides): Promise<void>;

    updateExecutionHandler(
      handledAddress: string,
      newExecutionHandler: string,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "ExecutionHandlerAdded(address,address)"(
      newHandledAddress?: string | null,
      executionHandler?: string | null
    ): TypedEventFilter<
      [string, string],
      { newHandledAddress: string; executionHandler: string }
    >;

    ExecutionHandlerAdded(
      newHandledAddress?: string | null,
      executionHandler?: string | null
    ): TypedEventFilter<
      [string, string],
      { newHandledAddress: string; executionHandler: string }
    >;

    "ExecutionHandlerUpdated(address,address)"(
      handledAddress?: string | null,
      newExecutionHandler?: string | null
    ): TypedEventFilter<
      [string, string],
      { handledAddress: string; newExecutionHandler: string }
    >;

    ExecutionHandlerUpdated(
      handledAddress?: string | null,
      newExecutionHandler?: string | null
    ): TypedEventFilter<
      [string, string],
      { handledAddress: string; newExecutionHandler: string }
    >;

    "OwnerUpdated(address,address)"(
      user?: string | null,
      newOwner?: string | null
    ): TypedEventFilter<[string, string], { user: string; newOwner: string }>;

    OwnerUpdated(
      user?: string | null,
      newOwner?: string | null
    ): TypedEventFilter<[string, string], { user: string; newOwner: string }>;
  };

  estimateGas: {
    addExecutionHandler(
      newHandledAddress: string,
      executionHandler: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    collectERC20(
      erc20: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    collectFees(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    executionHandlers(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    manageExecution(
      crowdfundContract: string,
      targetContract: string,
      assetContract: string,
      forumGroup: string,
      tokenId: BigNumberish,
      payload: BytesLike,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    owner(overrides?: CallOverrides): Promise<BigNumber>;

    setOwner(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    updateExecutionHandler(
      handledAddress: string,
      newExecutionHandler: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    addExecutionHandler(
      newHandledAddress: string,
      executionHandler: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    collectERC20(
      erc20: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    collectFees(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    executionHandlers(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    manageExecution(
      crowdfundContract: string,
      targetContract: string,
      assetContract: string,
      forumGroup: string,
      tokenId: BigNumberish,
      payload: BytesLike,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    owner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    setOwner(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    updateExecutionHandler(
      handledAddress: string,
      newExecutionHandler: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;
  };
}