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

interface FieldSVGs9Interface extends ethers.utils.Interface {
  functions: {
    "field_171(uint24[4])": FunctionFragment;
    "field_172(uint24[4])": FunctionFragment;
    "field_173(uint24[4])": FunctionFragment;
    "field_174(uint24[4])": FunctionFragment;
    "field_175(uint24[4])": FunctionFragment;
    "field_176(uint24[4])": FunctionFragment;
    "field_177(uint24[4])": FunctionFragment;
  };

  encodeFunctionData(
    functionFragment: "field_171",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_172",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_173",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_174",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_175",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_176",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;
  encodeFunctionData(
    functionFragment: "field_177",
    values: [[BigNumberish, BigNumberish, BigNumberish, BigNumberish]]
  ): string;

  decodeFunctionResult(functionFragment: "field_171", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_172", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_173", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_174", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_175", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_176", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "field_177", data: BytesLike): Result;

  events: {};
}

export class FieldSVGs9 extends BaseContract {
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

  interface: FieldSVGs9Interface;

  functions: {
    field_171(
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

    field_172(
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

    field_173(
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

    field_174(
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

    field_175(
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

    field_176(
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

    field_177(
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

  field_171(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_172(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_173(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_174(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_175(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_176(
    colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
    overrides?: CallOverrides
  ): Promise<
    [string, number, string] & {
      title: string;
      fieldType: number;
      svgString: string;
    }
  >;

  field_177(
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
    field_171(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_172(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_173(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_174(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_175(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_176(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<
      [string, number, string] & {
        title: string;
        fieldType: number;
        svgString: string;
      }
    >;

    field_177(
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
    field_171(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_172(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_173(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_174(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_175(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_176(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    field_177(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    field_171(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_172(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_173(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_174(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_175(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_176(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    field_177(
      colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish],
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}
