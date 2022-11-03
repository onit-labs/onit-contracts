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

interface ExecutionManagerInterface extends ethers.utils.Interface {
  functions: {
    "addProposalHandler(address,address)": FunctionFragment;
    "collectERC20(address)": FunctionFragment;
    "collectFees()": FunctionFragment;
    "manageExecution(address,uint256,bytes)": FunctionFragment;
    "nonCommissionContracts(address)": FunctionFragment;
    "owner()": FunctionFragment;
    "proposalHandlers(address)": FunctionFragment;
    "restrictedExecution()": FunctionFragment;
    "setOwner(address)": FunctionFragment;
    "setRestrictedExecution(uint256)": FunctionFragment;
    "toggleNonCommissionContract(address)": FunctionFragment;
    "updateProposalHandler(address,address)": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "addProposalHandler",
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
    functionFragment: "manageExecution",
    values: [string, BigNumberish, BytesLike]
  ): string;
  encodeFunctionData(
    functionFragment: "nonCommissionContracts",
    values: [string]
  ): string;
  encodeFunctionData(functionFragment: "owner", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "proposalHandlers",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "restrictedExecution",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "setOwner", values: [string]): string;
  encodeFunctionData(
    functionFragment: "setRestrictedExecution",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "toggleNonCommissionContract",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "updateProposalHandler",
    values: [string, string]
  ): string;

  decodeFunctionResult(
    functionFragment: "addProposalHandler",
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
    functionFragment: "manageExecution",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "nonCommissionContracts",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "owner", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "proposalHandlers",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "restrictedExecution",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "setOwner", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "setRestrictedExecution",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "toggleNonCommissionContract",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "updateProposalHandler",
    data: BytesLike
  ): Result;

  events: {
    "NonCommissionContracts(address,bool)": EventFragment;
    "OwnerUpdated(address,address)": EventFragment;
    "ProposalHandlerAdded(address,address)": EventFragment;
    "ProposalHandlerUpdated(address,address)": EventFragment;
    "RestrictedExecutionToggled(uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "NonCommissionContracts"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "OwnerUpdated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "ProposalHandlerAdded"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "ProposalHandlerUpdated"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "RestrictedExecutionToggled"): EventFragment;
}

export type NonCommissionContractsEvent = TypedEvent<
  [string, boolean] & { contractAddress: string; newCommissionSetting: boolean }
>;

export type OwnerUpdatedEvent = TypedEvent<
  [string, string] & { user: string; newOwner: string }
>;

export type ProposalHandlerAddedEvent = TypedEvent<
  [string, string] & { newHandledAddress: string; proposalHandler: string }
>;

export type ProposalHandlerUpdatedEvent = TypedEvent<
  [string, string] & { handledAddress: string; newProposalHandler: string }
>;

export type RestrictedExecutionToggledEvent = TypedEvent<
  [BigNumber] & { newRestrictionSetting: BigNumber }
>;

export class ExecutionManager extends BaseContract {
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

  interface: ExecutionManagerInterface;

  functions: {
    addProposalHandler(
      newHandledAddress: string,
      proposalHandler: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    collectERC20(
      erc20: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    collectFees(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    manageExecution(
      target: string,
      value: BigNumberish,
      payload: BytesLike,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    nonCommissionContracts(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    owner(overrides?: CallOverrides): Promise<[string]>;

    proposalHandlers(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<[string]>;

    restrictedExecution(overrides?: CallOverrides): Promise<[BigNumber]>;

    setOwner(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    setRestrictedExecution(
      _restrictedExecution: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    toggleNonCommissionContract(
      nonCommissionContract: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    updateProposalHandler(
      handledAddress: string,
      newProposalHandler: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;
  };

  addProposalHandler(
    newHandledAddress: string,
    proposalHandler: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  collectERC20(
    erc20: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  collectFees(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  manageExecution(
    target: string,
    value: BigNumberish,
    payload: BytesLike,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  nonCommissionContracts(
    arg0: string,
    overrides?: CallOverrides
  ): Promise<boolean>;

  owner(overrides?: CallOverrides): Promise<string>;

  proposalHandlers(arg0: string, overrides?: CallOverrides): Promise<string>;

  restrictedExecution(overrides?: CallOverrides): Promise<BigNumber>;

  setOwner(
    newOwner: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  setRestrictedExecution(
    _restrictedExecution: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  toggleNonCommissionContract(
    nonCommissionContract: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  updateProposalHandler(
    handledAddress: string,
    newProposalHandler: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    addProposalHandler(
      newHandledAddress: string,
      proposalHandler: string,
      overrides?: CallOverrides
    ): Promise<void>;

    collectERC20(erc20: string, overrides?: CallOverrides): Promise<void>;

    collectFees(overrides?: CallOverrides): Promise<void>;

    manageExecution(
      target: string,
      value: BigNumberish,
      payload: BytesLike,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    nonCommissionContracts(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<boolean>;

    owner(overrides?: CallOverrides): Promise<string>;

    proposalHandlers(arg0: string, overrides?: CallOverrides): Promise<string>;

    restrictedExecution(overrides?: CallOverrides): Promise<BigNumber>;

    setOwner(newOwner: string, overrides?: CallOverrides): Promise<void>;

    setRestrictedExecution(
      _restrictedExecution: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    toggleNonCommissionContract(
      nonCommissionContract: string,
      overrides?: CallOverrides
    ): Promise<void>;

    updateProposalHandler(
      handledAddress: string,
      newProposalHandler: string,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "NonCommissionContracts(address,bool)"(
      contractAddress?: null,
      newCommissionSetting?: null
    ): TypedEventFilter<
      [string, boolean],
      { contractAddress: string; newCommissionSetting: boolean }
    >;

    NonCommissionContracts(
      contractAddress?: null,
      newCommissionSetting?: null
    ): TypedEventFilter<
      [string, boolean],
      { contractAddress: string; newCommissionSetting: boolean }
    >;

    "OwnerUpdated(address,address)"(
      user?: string | null,
      newOwner?: string | null
    ): TypedEventFilter<[string, string], { user: string; newOwner: string }>;

    OwnerUpdated(
      user?: string | null,
      newOwner?: string | null
    ): TypedEventFilter<[string, string], { user: string; newOwner: string }>;

    "ProposalHandlerAdded(address,address)"(
      newHandledAddress?: string | null,
      proposalHandler?: string | null
    ): TypedEventFilter<
      [string, string],
      { newHandledAddress: string; proposalHandler: string }
    >;

    ProposalHandlerAdded(
      newHandledAddress?: string | null,
      proposalHandler?: string | null
    ): TypedEventFilter<
      [string, string],
      { newHandledAddress: string; proposalHandler: string }
    >;

    "ProposalHandlerUpdated(address,address)"(
      handledAddress?: string | null,
      newProposalHandler?: string | null
    ): TypedEventFilter<
      [string, string],
      { handledAddress: string; newProposalHandler: string }
    >;

    ProposalHandlerUpdated(
      handledAddress?: string | null,
      newProposalHandler?: string | null
    ): TypedEventFilter<
      [string, string],
      { handledAddress: string; newProposalHandler: string }
    >;

    "RestrictedExecutionToggled(uint256)"(
      newRestrictionSetting?: BigNumberish | null
    ): TypedEventFilter<[BigNumber], { newRestrictionSetting: BigNumber }>;

    RestrictedExecutionToggled(
      newRestrictionSetting?: BigNumberish | null
    ): TypedEventFilter<[BigNumber], { newRestrictionSetting: BigNumber }>;
  };

  estimateGas: {
    addProposalHandler(
      newHandledAddress: string,
      proposalHandler: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    collectERC20(
      erc20: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    collectFees(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    manageExecution(
      target: string,
      value: BigNumberish,
      payload: BytesLike,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    nonCommissionContracts(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    owner(overrides?: CallOverrides): Promise<BigNumber>;

    proposalHandlers(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    restrictedExecution(overrides?: CallOverrides): Promise<BigNumber>;

    setOwner(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    setRestrictedExecution(
      _restrictedExecution: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    toggleNonCommissionContract(
      nonCommissionContract: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    updateProposalHandler(
      handledAddress: string,
      newProposalHandler: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    addProposalHandler(
      newHandledAddress: string,
      proposalHandler: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    collectERC20(
      erc20: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    collectFees(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    manageExecution(
      target: string,
      value: BigNumberish,
      payload: BytesLike,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    nonCommissionContracts(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    owner(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    proposalHandlers(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    restrictedExecution(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    setOwner(
      newOwner: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    setRestrictedExecution(
      _restrictedExecution: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    toggleNonCommissionContract(
      nonCommissionContract: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    updateProposalHandler(
      handledAddress: string,
      newProposalHandler: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;
  };
}
