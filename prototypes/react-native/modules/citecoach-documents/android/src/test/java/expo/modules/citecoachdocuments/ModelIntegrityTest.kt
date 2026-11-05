package expo.modules.citecoachdocuments

import java.io.File
import org.junit.Assert.*
import org.junit.Test

class ModelIntegrityTest {
  private val bytes=byteArrayOf(0x47,0x47,0x55,0x46,1,2,3,4)
  private val sha="7062dd2ff284798e57726700b6697c8238b9ba1c612c1496a4630757c7bbc3ed"
  private fun withFile(block:(File)->Unit) {
    val file=File.createTempFile("citecoach-model-", ".gguf")
    try { file.writeBytes(bytes);block(file) } finally { file.delete() }
  }
  @Test fun acceptsCompleteVerifiedPackage() = withFile { file ->
    assertTrue(ModelIntegrity.verify(file,8L,sha))
  }
  @Test fun rejectsSameSizeCorruptionEvenWithValidHeader() = withFile { file ->
    file.writeBytes(bytes.copyOf().apply { this[7]=9 })
    assertTrue(ModelIntegrity.hasExpectedHeaderAndSize(file,8L))
    assertFalse(ModelIntegrity.verify(file,8L,sha))
  }
  @Test fun rejectsPartialDownloadsAndDifferentPackageSizes() = withFile { file ->
    assertFalse(ModelIntegrity.verify(file,16L,sha))
    file.writeBytes(bytes.copyOf(4))
    assertFalse(ModelIntegrity.verify(file,8L,sha))
  }
  @Test fun rejectsWebErrorPayloads() = withFile { file ->
    file.writeText("HTML1234")
    assertFalse(ModelIntegrity.hasExpectedHeaderAndSize(file,8L))
    assertFalse(ModelIntegrity.verify(file,8L,sha))
  }
}
