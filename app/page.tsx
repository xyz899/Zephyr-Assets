import "./layout";
import "../styles/globals.css";
import React from "react";
import { Why1 } from "@/app/utils/Text";
import PurposePart from "@/app/components/PurposePart";
import Showcase from "@/app/utils/Showcase";
import FadeUp from "@/app/components/fadeEffect";
import Steps from "@/app/components/Steps";
import FAQ from "@/app/utils/FAQ";
import PromotionalSection from "./components/Popup";
// import { DAppProvider, useEthers, Mainnet, Config, getDefaultProvider } from '@usedapp/core';

const Home = () => {
  return (
    <main>
      <FadeUp>
        <PromotionalSection/>
        <Showcase/>
        <PurposePart/>
        <section className="bg-white grid grid-cols-3 backdrop-blur-sm text-center justify-end text-white">
          <div className="p-6 rounded-lg">
            <h2 className="p-4 mt-4 mb-6 shadow-xl font-bold text-2xl inline-block rounded-xl ring-2 ring-purple-400 text-white bg-black">
              Why should you Tokenize your assets ?
            </h2>
            <Why1/>
          </div>
            {/* <img src="./home_imgs/woman.jpg" alt="" className=" w-[500px] items-end "/> */}
        </section>
        <section className=" mx-auto">
          
          <FAQ/>
        </section>
      </FadeUp>
    </main>
  );
};

export default Home;
