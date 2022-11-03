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

interface HardwareSVGs10Interface extends ethers.utils.Interface {
  functions: {
    "hardware_38()": FunctionFragment;
    "hardware_39()": FunctionFragment;
    "hardware_40()": FunctionFragment;
    "hardware_41()": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "hardware_38",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "hardware_39",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "hardware_40",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "hardware_41",
    values?: undefined
  ): string;

  decodeFunctionResult(
    functionFragment: "hardware_38",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "hardware_39",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "hardware_40",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "hardware_41",
    data: BytesLike
  ): Result;

  events: {};
}

export class HardwareSVGs10 extends BaseContract {
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

  interface: HardwareSVGs10Interface;

  functions: {
    hardware_38(
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

    hardware_39(
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

    hardware_40(
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

    hardware_41(
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

  hardware_38(
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      hardwareType: number;
      svgString: string;
    }
  >;

  hardware_39(
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      hardwareType: number;
      svgString: string;
    }
  >;

  hardware_40(
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      hardwareType: number;
      svgString: string;
    }
  >;

  hardware_41(
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      hardwareType: number;
      svgString: string;
    }
  >;

  callStatic: {
    hardware_38(
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        hardwareType: number;
        svgString: string;
      }
    >;

    hardware_39(
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        hardwareType: number;
        svgString: string;
      }
    >;

    hardware_40(
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        hardwareType: number;
        svgString: string;
      }
    >;

    hardware_41(
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
    hardware_38(overrides?: CallOverrides): Promise<BigNumber>;

    hardware_39(overrides?: CallOverrides): Promise<BigNumber>;

    hardware_40(overrides?: CallOverrides): Promise<BigNumber>;

    hardware_41(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    hardware_38(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    hardware_39(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    hardware_40(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    hardware_41(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}
