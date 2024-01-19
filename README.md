This code is based on [VulkanLaunchpad](https://github.com/cg-tuwien/VulkanLaunchpad) from TU Wien, a framework targeted at those learning Vulkan. It abstracts some of the hard and overly verbose parts of the Vulkan C API.
## Demos
![celestial bodies rotating](https://github.com/ethangillengg/virtual-orrery/assets/81479108/4bd2005c-722b-44a4-b95e-bbe512c2de1c)
> Celestial bodies orbit as time progresses
 
![fast-orbiting](https://github.com/ethangillengg/virtual-orrery/assets/81479108/1154c4ef-d6d9-4b62-bbbd-589cc2bc11b0)
> User can increase the speed of time (and reverse it)

![toggle-phong-shading](https://github.com/ethangillengg/virtual-orrery/assets/81479108/73b2e9ab-df96-4ead-b5f8-939a0a29821e)
> Toggle shading (Phong and shadow casting)

![rotations-zoom](https://github.com/ethangillengg/virtual-orrery/assets/81479108/d248a137-2301-4824-b689-4bbda755194e)
> User controlled camera with all rotation axes and zoom
## Usage
### Controls
#### Rotations
- `W`: Increment roll
- `S`: Decrement roll
- `A`: Increment yaw
- `D`: Decrement yaw
- `Q`: Increment pitch
- `E`: Decrement pitch

#### Time

- `L/Right`: Increment time
- `H/Left`: Decrement time

#### Scaling

- `K/Up`: Increment scaling
- `J/Down`: Decrement scaling

#### Miscellaneous

- `Space`: Toggle intrinsic/extrinsic rotation mode
- `Tab`: Toggle shading (both phong and shadow casting)
- `R`: Reset to initial state

#### Modifiers
- `Shift`: Increase increment/decrement for time, scaling, or zoom while held down

## Setup
### Using the provided Nix flake
1. [Install Nix](https://nixos.org/download.html)
2. Run the flake:
```sh
nix run 'git+https://github.com/ethangillengg/virtual-orrery?submodules=1' --experimental-features 'nix-command flakes'
```

### Manual
1. Clone this repository:
```sh
git clone https://github.com/ethangillengg/virtual-orrery
```
2. Optionally, in your project directory, create a new folder called build and change into it:
```sh
mkdir build
cd build
```
3. Use cmake to generate the necessary files for compiling the project. Please review the [Setup Instructions](https://github.com/cg-tuwien/VulkanLaunchpad#setup-instructions) for `VulkanLaunchpadStarter` to setup your IDE and build environment. For this step, you can either use cmake-gui or run the cmake command directly in the terminal:
```sh
cmake ..
```
4. You can now compile and run your project. In most cases, this is as simple as:
```sh
make -j
HW4/HW4
```

The main executable takes only one optional argument on the command line: the path to the assets it needs. This only needs to be invoked if the program is somehow unable to find the assets directory, which is unlikely to occur during normal development.

## Troubleshooting

- Make sure that Vulkan SDK is installed correctly. You can verify this by running the vkCube application. (Installed automatically when you install Vulkan SDK)

- For Linux, you need to install build-essentials.

- For windows, ensure that the c++ desktop development kit is installed inside visual studio. You can use developer command prompt in windows.

- For macOS, you must have the latest version of OS and Xcode installed.
