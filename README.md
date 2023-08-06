# secret-of-mana-hacking

We are trying to hack Secret Of Mana, the main goal is to create a new editor of our favorite game.

At the moment we are a team composed of two fan of SoM
  - smK
  - Tomm

Tomm knows quite a lot the code of the game and smK (myself) code the main function of the code.

So what we have now?

We begun with Excel Macro, which can be a little weird at the first glimpse but actually, it is quite convenient to work with.

So the  main feature right now are:

- Display a room with its original game code on a sheet (image 1)
- Display a room with its uncompressed code on a sheet (image 2)
- Recompress a room with our original compressor (image 3)
- 
![Alt text](/Images%20GitHub/Room6_original_code.png?raw=true "Image 1")
![Alt text](/Images%20GitHub/Room6_uncompressed_code.png?raw=true "Image 2")
![Alt text](/Images%20GitHub/Room6_compressed_code.png?raw=true "Image 3")

Note our compressor is mire efficient than the original and it is working on the game.
On this example, the room number is 6.
Number of bytes in the original game = 1168
Number of byteswith our compressor = 1162
It's still possible to optimize more but will require a lot of work.

Tomm is currently experiencing news level design throught this new compressing function.
Here is an example of its creation:



Keep in touch!
