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

interface FieldSVGs17Interface extends ethers.utils.Interface {
  functions: {
    "field_228(uint24[4])": FunctionFragment;
    "field_229(uint24[4])": FunctionFragment;
    "field_230(uint24[4])": FunctionFragment;
    "field_231(uint24[4])": FunctionFragment;
    "field_232(uint24[4])": FunctionFragment;
    "field_233(uint24[4])": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "field_228",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_229",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_230",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_231",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_232",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_233",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;

  decodeFunctionResult(functionFragment: "field_228", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_229", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_230", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_231", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_232", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_233", data: BytesLike): Result;

  events: {};
}

export class FieldSVGs17 extends BaseContract {
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

  interface: FieldSVGs17Interface;

  functions: {
    field_228(
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

    field_229(
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

    field_230(
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

    field_231(
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

    field_232(
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

    field_233(
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

  field_228(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_229(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_230(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_231(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_232(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_233(
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
    field_228(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_229(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_230(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_231(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_232(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_233(
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
    field_228(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_229(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_230(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_231(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_232(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_233(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    field_228(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_229(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_230(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_231(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_232(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_233(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}
