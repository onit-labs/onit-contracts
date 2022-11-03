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

interface FieldSVGs13Interface extends ethers.utils.Interface {
  functions: {
    "field_206(uint24[4])": FunctionFragment;
    "field_207(uint24[4])": FunctionFragment;
    "field_208(uint24[4])": FunctionFragment;
    "field_209(uint24[4])": FunctionFragment;
    "field_210(uint24[4])": FunctionFragment;
    "field_211(uint24[4])": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "field_206",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_207",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_208",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_209",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_210",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_211",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;

  decodeFunctionResult(functionFragment: "field_206", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_207", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_208", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_209", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_210", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_211", data: BytesLike): Result;

  events: {};
}

export class FieldSVGs13 extends BaseContract {
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

  interface: FieldSVGs13Interface;

  functions: {
    field_206(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [
        [string, number, string] & {
          title: string;
          fieldType: number;
          svgString: string;
        }
      ]
    >;

    field_207(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [
        [string, number, string] & {
          title: string;
          fieldType: number;
          svgString: string;
        }
      ]
    >;

    field_208(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [
        [string, number, string] & {
          title: string;
          fieldType: number;
          svgString: string;
        }
      ]
    >;

    field_209(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [
        [string, number, string] & {
          title: string;
          fieldType: number;
          svgString: string;
        }
      ]
    >;

    field_210(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [
        [string, number, string] & {
          title: string;
          fieldType: number;
          svgString: string;
        }
      ]
    >;

    field_211(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [
        [string, number, string] & {
          title: string;
          fieldType: number;
          svgString: string;
        }
      ]
    >;
  };

  field_206(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_207(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_208(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_209(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_210(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_211(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  callStatic: {
    field_206(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_207(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_208(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_209(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_210(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_211(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;
  };

  filters: {};

  estimateGas: {
    field_206(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_207(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_208(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_209(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_210(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_211(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    field_206(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_207(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_208(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_209(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_210(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_211(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}
