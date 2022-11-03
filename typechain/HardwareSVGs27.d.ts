/* Autogenerated file. Do not edit manually. */

/* tslint:disable */

/* eslint-disable */
import type { TypedEventFilter, TypedEvent, TypedListener } from "./common";
import { FunctionFragment, EventFragment, Result } from "@ethersproject/abi";
import { BytesLike } from "@ethersproject/bytes";
import { Listener, Provider } from "@ethersproject/providers";
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

interface HardwareSVGs27Interface extends ethers.utils.Interface {
  functions: {
    "hardware_91()": FunctionFragment;
    "hardware_92()": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "hardware_91",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "hardware_92",
    values?: undefined
  ): string;

  decodeFunctionResult(
    functionFragment: "hardware_91",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "hardware_92",
    data: BytesLike
  ): Result;

  events: {};
}

export class HardwareSVGs27 extends BaseContract {
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

  interface: HardwareSVGs27Interface;

  functions: {
    hardware_91(
      overrides?: CallOverrides
    ): Promise<
      [
        [string, number, string] & {
          title: string;
          hardwareType: number;
          svgString: string;
        }
      ]
    >;

    hardware_92(
      overrides?: CallOverrides
    ): Promise<
      [
        [string, number, string] & {
          title: string;
          hardwareType: number;
          svgString: string;
        }
      ]
    >;
  };

  hardware_91(
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      hardwareType: number;
      svgString: string;
    }
  >;

  hardware_92(
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      hardwareType: number;
      svgString: string;
    }
  >;

  callStatic: {
    hardware_91(
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        hardwareType: number;
        svgString: string;
      }
    >;

    hardware_92(
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        hardwareType: number;
        svgString: string;
      }
    >;
  };

  filters: {};

  estimateGas: {
    hardware_91(overrides?: CallOverrides): Promise<BigNumber>;

    hardware_92(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    hardware_91(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    hardware_92(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}
