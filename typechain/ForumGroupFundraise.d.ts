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
  PayableOverrides,
  CallOverrides,
} from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { Listener, Provider } from "@ethersproject/providers";
import { FunctionFragment, EventFragment, Result } from "@ethersproject/abi";
import type { TypedEventFilter, TypedEvent, TypedListener } from "./common";

interface ForumGroupFundraiseInterface extends ethers.utils.Interface {
  functions: {
    "cancelFundRound(address)": FunctionFragment;
    "contributionTracker(address,address)": FunctionFragment;
    "getFund(address)": FunctionFragment;
    "initiateFundRound(address,uint256,uint256)": FunctionFragment;
    "processFundRound(address)": FunctionFragment;
    "submitFundContribution(address)": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "cancelFundRound",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "contributionTracker",
    values: [string, string]
  ): string;
  encodeFunctionData(functionFragment: "getFund", values: [string]): string;
  encodeFunctionData(
    functionFragment: "initiateFundRound",
    values: [string, BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "processFundRound",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "submitFundContribution",
    values: [string]
  ): string;

  decodeFunctionResult(
    functionFragment: "cancelFundRound",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "contributionTracker",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "getFund", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "initiateFundRound",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "processFundRound",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "submitFundContribution",
    data: BytesLike
  ): Result;

  events: {
    "FundRoundCancelled(address)": EventFragment;
    "FundRoundReleased(address,address[],uint256)": EventFragment;
    "NewFundContribution(address,address,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "FundRoundCancelled"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "FundRoundReleased"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "NewFundContribution"): EventFragment;
}

export type FundRoundCancelledEvent = TypedEvent<
  [string] & { groupAddress: string }
>;

export type FundRoundReleasedEvent = TypedEvent<
  [string, string[], BigNumber] & {
    groupAddress: string;
    contributors: string[];
    individualContribution: BigNumber;
  }
>;

export type NewFundContributionEvent = TypedEvent<
  [string, string, BigNumber] & {
    groupAddress: string;
    proposer: string;
    value: BigNumber;
  }
>;

export class ForumGroupFundraise extends BaseContract {
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

  interface: ForumGroupFundraiseInterface;

  functions: {
    cancelFundRound(
      groupAddress: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    contributionTracker(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    getFund(
      groupAddress: string,
      overrides?: CallOverrides
    ): Promise<
      [
        [string[], BigNumber, BigNumber, BigNumber] & {
          contributors: string[];
          individualContribution: BigNumber;
          valueNumerator: BigNumber;
          valueDenominator: BigNumber;
        }
      ] & {
        fundDetails: [string[], BigNumber, BigNumber, BigNumber] & {
          contributors: string[];
          individualContribution: BigNumber;
          valueNumerator: BigNumber;
          valueDenominator: BigNumber;
        };
      }
    >;

    initiateFundRound(
      groupAddress: string,
      valueNumerator: BigNumberish,
      valueDenominator: BigNumberish,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    processFundRound(
      groupAddress: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    submitFundContribution(
      groupAddress: string,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;
  };

  cancelFundRound(
    groupAddress: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  contributionTracker(
    arg0: string,
    arg1: string,
    overrides?: CallOverrides
  ): Promise<boolean>;

  getFund(
    groupAddress: string,
    overrides?: CallOverrides
  ): Promise<
    [string[], BigNumber, BigNumber, BigNumber] & {
      contributors: string[];
      individualContribution: BigNumber;
      valueNumerator: BigNumber;
      valueDenominator: BigNumber;
    }
  >;

  initiateFundRound(
    groupAddress: string,
    valueNumerator: BigNumberish,
    valueDenominator: BigNumberish,
    overrides?: PayableOverrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  processFundRound(
    groupAddress: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  submitFundContribution(
    groupAddress: string,
    overrides?: PayableOverrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    cancelFundRound(
      groupAddress: string,
      overrides?: CallOverrides
    ): Promise<void>;

    contributionTracker(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<boolean>;

    getFund(
      groupAddress: string,
      overrides?: CallOverrides
    ): Promise<
      [string[], BigNumber, BigNumber, BigNumber] & {
        contributors: string[];
        individualContribution: BigNumber;
        valueNumerator: BigNumber;
        valueDenominator: BigNumber;
      }
    >;

    initiateFundRound(
      groupAddress: string,
      valueNumerator: BigNumberish,
      valueDenominator: BigNumberish,
      overrides?: CallOverrides
    ): Promise<void>;

    processFundRound(
      groupAddress: string,
      overrides?: CallOverrides
    ): Promise<void>;

    submitFundContribution(
      groupAddress: string,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {
    "FundRoundCancelled(address)"(
      groupAddress?: string | null
    ): TypedEventFilter<[string], { groupAddress: string }>;

    FundRoundCancelled(
      groupAddress?: string | null
    ): TypedEventFilter<[string], { groupAddress: string }>;

    "FundRoundReleased(address,address[],uint256)"(
      groupAddress?: string | null,
      contributors?: null,
      individualContribution?: null
    ): TypedEventFilter<
      [string, string[], BigNumber],
      {
        groupAddress: string;
        contributors: string[];
        individualContribution: BigNumber;
      }
    >;

    FundRoundReleased(
      groupAddress?: string | null,
      contributors?: null,
      individualContribution?: null
    ): TypedEventFilter<
      [string, string[], BigNumber],
      {
        groupAddress: string;
        contributors: string[];
        individualContribution: BigNumber;
      }
    >;

    "NewFundContribution(address,address,uint256)"(
      groupAddress?: string | null,
      proposer?: string | null,
      value?: null
    ): TypedEventFilter<
      [string, string, BigNumber],
      { groupAddress: string; proposer: string; value: BigNumber }
    >;

    NewFundContribution(
      groupAddress?: string | null,
      proposer?: string | null,
      value?: null
    ): TypedEventFilter<
      [string, string, BigNumber],
      { groupAddress: string; proposer: string; value: BigNumber }
    >;
  };

  estimateGas: {
    cancelFundRound(
      groupAddress: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    contributionTracker(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    getFund(
      groupAddress: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    initiateFundRound(
      groupAddress: string,
      valueNumerator: BigNumberish,
      valueDenominator: BigNumberish,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    processFundRound(
      groupAddress: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    submitFundContribution(
      groupAddress: string,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    cancelFundRound(
      groupAddress: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    contributionTracker(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    getFund(
      groupAddress: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    initiateFundRound(
      groupAddress: string,
      valueNumerator: BigNumberish,
      valueDenominator: BigNumberish,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    processFundRound(
      groupAddress: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    submitFundContribution(
      groupAddress: string,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;
  };
}
