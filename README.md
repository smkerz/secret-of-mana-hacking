# secret-of-mana-hacking

We are trying to hack Secret Of Mana, the main goal is to create a new editor for our favorite game.

At the moment we are a team composed of two fans of SoM
  - Tomm
  - smK

Tomm knows quite a lot the code of the game and smK (myself) codes the main function of the code.

So what we have now?

We begun with Excel Macro, which can be a little weird at the first glimpse but actually, it is quite convenient to work with.

So the main features right now are:

- Display a room with its original game code on a sheet (image 1)
- Display a room with its uncompressed code on a sheet (image 2)
- Recompress a room with our original compressor (image 3)

<table border="0">
<tr>
<td>Image 1</td>
<td>Image 2</td>
<td>Image 3</td>
</tr>
<tr>
<td><img src="/Images%20GitHub/Room6_original_code.png" alt="Image 1" style="width:200px;"/></td>
<td><img src="/Images%20GitHub/Room6_uncompressed_code.png" alt="Image 2" style="width:200px;"/></td>
<td><img src="/Images%20GitHub/Room6_compressed_code.png" alt="Image 3" style="width:200px;"/></td>
</tr>
</table>

Note our compressor is more efficient than the original and it is working in game.
On this example, the room number is 6.
- Number of bytes in the original game = 1168
- Number of bytes with our compressor = 1162

It's still possible to optimize and earn some bytes but it will require a lot of work.

Tomm is currently experimenting a new level design throught this new compressing function.
Here is an example of his creation:

<img src="/Images%20GitHub/Tomm_room.png" alt="Tomm Room" style="width:200px;"/>

Keep in touch!
