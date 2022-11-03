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
  CallOverrides,
} from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { Listener, Provider } from "@ethersproject/providers";
import { FunctionFragment, EventFragment, Result } from "@ethersproject/abi";
import type { TypedEventFilter, TypedEvent, TypedListener } from "./common";

interface EmblemWeaverInterface extends ethers.utils.Interface {
  functions: {
    "fieldGenerator()": FunctionFragment;
    "frameGenerator()": FunctionFragment;
    "generateShieldPass()": FunctionFragment;
    "generateShieldURI((uint16,uint16[9],uint16,uint24[4],bytes32,bytes32))": FunctionFragment;
    "hardwareGenerator()": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "fieldGenerator",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "frameGenerator",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "generateShieldPass",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "generateShieldURI",
    values: [
      {
        field: BigNumberish;
        hardware: [
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish
        ];
        frame: BigNumberish;
        colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish];
        shieldHash: BytesLike;
        hardwareConfiguration: BytesLike;
      }
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "hardwareGenerator",
    values?: undefined
  ): string;

  decodeFunctionResult(
    functionFragment: "fieldGenerator",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "frameGenerator",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "generateShieldPass",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "generateShieldURI",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "hardwareGenerator",
    data: BytesLike
  ): Result;

  events: {};
}

export class EmblemWeaver extends BaseContract {
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

  interface: EmblemWeaverInterface;

  functions: {
    fieldGenerator(overrides?: CallOverrides): Promise<[string]>;

    frameGenerator(overrides?: CallOverrides): Promise<[string]>;

    generateShieldPass(overrides?: CallOverrides): Promise<[string]>;

    generateShieldURI(
      shield: {
        field: BigNumberish;
        hardware: [
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish
        ];
        frame: BigNumberish;
        colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish];
        shieldHash: BytesLike;
        hardwareConfiguration: BytesLike;
      },
      overrides?: CallOverrides
    ): Promise<[string]>;

    hardwareGenerator(overrides?: CallOverrides): Promise<[string]>;
  };

  fieldGenerator(overrides?: CallOverrides): Promise<string>;

  frameGenerator(overrides?: CallOverrides): Promise<string>;

  generateShieldPass(overrides?: CallOverrides): Promise<string>;

  generateShieldURI(
    shield: {
      field: BigNumberish;
      hardware: [
        BigNumberish,
        BigNumberish,
        BigNumberish,
        BigNumberish,
        BigNumberish,
        BigNumberish,
        BigNumberish,
        BigNumberish,
        BigNumberish
      ];
      frame: BigNumberish;
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish];
      shieldHash: BytesLike;
      hardwareConfiguration: BytesLike;
    },
    overrides?: CallOverrides
  ): Promise<string>;

  hardwareGenerator(overrides?: CallOverrides): Promise<string>;

  callStatic: {
    fieldGenerator(overrides?: CallOverrides): Promise<string>;

    frameGenerator(overrides?: CallOverrides): Promise<string>;

    generateShieldPass(overrides?: CallOverrides): Promise<string>;

    generateShieldURI(
      shield: {
        field: BigNumberish;
        hardware: [
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish
        ];
        frame: BigNumberish;
        colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish];
        shieldHash: BytesLike;
        hardwareConfiguration: BytesLike;
      },
      overrides?: CallOverrides
    ): Promise<string>;

    hardwareGenerator(overrides?: CallOverrides): Promise<string>;
  };

  filters: {};

  estimateGas: {
    fieldGenerator(overrides?: CallOverrides): Promise<BigNumber>;

    frameGenerator(overrides?: CallOverrides): Promise<BigNumber>;

    generateShieldPass(overrides?: CallOverrides): Promise<BigNumber>;

    generateShieldURI(
      shield: {
        field: BigNumberish;
        hardware: [
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish
        ];
        frame: BigNumberish;
        colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish];
        shieldHash: BytesLike;
        hardwareConfiguration: BytesLike;
      },
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    hardwareGenerator(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    fieldGenerator(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    frameGenerator(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    generateShieldPass(
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    generateShieldURI(
      shield: {
        field: BigNumberish;
        hardware: [
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish,
          BigNumberish
        ];
        frame: BigNumberish;
        colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish];
        shieldHash: BytesLike;
        hardwareConfiguration: BytesLike;
      },
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    hardwareGenerator(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}
