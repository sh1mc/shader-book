using System.IO;
using UnityEditor;
using UnityEngine;

public sealed class BookEditor : EditorWindow
{
    private int m_width = 1024;
    private int m_height = 1024;
    private int m_linenum = 28;
    private string m_path = "Assets/VTex/books/sample.png";
    private string m_text;

    [MenuItem("Window/BookEditor")]
    private static void CreateWindow()
    {
        var rect = new Rect(0, 0, 322, 500);

        GetWindowWithRect<BookEditor>(rect);
    }

    private void OnGUI()
    {
        /*
        m_width  = EditorGUILayout.IntField( "Width", m_width );
        m_height = EditorGUILayout.IntField( "Height", m_height );
        */
        m_width = 1024;
        m_height = 1024;
        m_linenum = EditorGUILayout.IntField("Charcters in one line", m_linenum);
        m_path = EditorGUILayout.TextField("Path", m_path);
        if (GUILayout.Button("Create and Save"))
        {
            CreateAndSave(m_width, m_height, m_linenum, m_path, m_text);
        }
        m_text = EditorGUILayout.TextArea(m_text);


    }

    private static void DotTexture(Texture2D texture, int height, int width, char c, int count)
    {
        int charcode = (int)c;
        int y = height - count / width;
        int x = count % width;
        int r = ((charcode & 0x00ff0000) >> 16);
        int g = ((charcode & 0x0000ff00) >> 8);
        int b = ((charcode & 0x000000ff));
        float rf = (float)r / (float)0xff;
        float gf = (float)g / (float)0xff;
        float bf = (float)b / (float)0xff;
        Color col = new Color(rf, gf, bf, 1.0f);
        texture.SetPixel(x, y, col);
    }

    private static void CreateAndSave(int width, int height, int linenum, string path, string text)
    {
        var texture = new Texture2D
        (
            width: width,
            height: height,
            textureFormat: TextureFormat.ARGB32,
            mipChain: false,
            linear: false
        );

        int count = 0;

        for (int i = 0; i < height; i++)
        {
            for (int j = 0; j < width; j++)
            {
                texture.SetPixel(j, i, Color.black);
            }
        }

        foreach (char c in text)
        {
            DotTexture(texture, height, width, c, count);
            count++;
            if (c == '\n') {
                while ((count) % linenum != 0) {
                    DotTexture(texture, height, width, ' ', count);
                    count++;
                }
            }
        }

        var bytes = texture.EncodeToPNG();

        var uniquePath = AssetDatabase.GenerateUniqueAssetPath(path);

        File.WriteAllBytes(uniquePath, bytes);

        AssetDatabase.Refresh();
    }
}