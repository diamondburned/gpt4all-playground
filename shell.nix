{ pkgs ? import <nixpkgs> {} }:

let
	gpt4all_src = pkgs.fetchFromGitHub {
		owner = "nomic-ai";
		repo = "gpt4all";
		# I don't think nomic-ai knows how to use git tags, so we'll just grab the
		# commit hash directly.
		rev = "f0735efa7";
		sha256 = "sha256-CVr2rvT9RO4EuHokT/Zz+PNk1rjnN7nE1W+02/W+fhw=";
		fetchSubmodules = true;
	};

	libgpt4all = pkgs.stdenv.mkDerivation rec {
		pname = "libgpt4all";

		version = gpt4all_src.rev;
		src = gpt4all_src;

		nativeBuildInputs = with pkgs; [
			cmake
			git
		];

		buildInputs = with pkgs; [
			vulkan-headers
			vulkan-loader
			vulkan-tools
			shaderc
			kompute
		];

		phases = [ "unpackPhase" "fixupPhase" "buildPhase" "installPhase" ];

		fixupPhase = ''
			# Do not allow LLaMa to build Kompute on its own because we already have Kompute and Meta
			# engineers are too dumb to understand the concept of installing something.
			rm $(find . -path '*/kompute/CMakeLists.txt')
		'';

		buildPhase = ''
			cd gpt4all-bindings/golang
			make libgpt4all.a
			cd ../../
		'';

		installPhase = ''
			mkdir -p $out/lib
			install -m 644 gpt4all-bindings/golang/libgpt4all.a $out/lib
			install -m 644 gpt4all-bindings/golang/llmodel.o    $out/lib
			install -m 644 gpt4all-bindings/golang/llmodel_c.o  $out/lib
			for so in gpt4all-bindings/golang/buildllm/*.so*; do
				install -m 644 $so $out/lib
			done
		'';
	};
in

pkgs.mkShell {
	buildInputs = with pkgs; [
		libgpt4all
		aria2

		# Go
		go
		gopls

		# Python
		python3
		pyright
	];

	shellHook = ''
		python3 -m venv .venv
		source .venv/bin/activate
		mkdir -p .models
		ln -s ${gpt4all_src}/gpt4all-bindings/golang go/gpt4all
	'';

	LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
		"${libgpt4all}/lib"
		# C++ libraries
		"${pkgs.stdenv.cc.cc.lib}"
	];
	GPT4ALL_MODELS = "${builtins.toString ./.}/.models";
}
