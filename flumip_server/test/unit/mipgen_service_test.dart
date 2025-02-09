import 'dart:io';

import 'package:flumip_server/src/services/mipgen_service.dart';
import 'package:test/test.dart';

void main() {
  test("projectCreation", () async {
    final mipgenService = MipgenService();

    bool result = await mipgenService.createProject("test");
    expect(result, true);

    result = await mipgenService.createProject("test");
    expect(result, false);

    mipgenService.deleteProject("test");
  });

  test("projectDeletion", () async {
    final mipgenService = MipgenService();

    await mipgenService.createProject("testToDelete");
    var result = await mipgenService.checkProjectExists("testToDelete");
    expect(result, true);

    mipgenService.deleteProject("testToDelete");
    await Future.delayed(Duration(seconds: 1));
    expect(await mipgenService.checkProjectExists("testToDelete"), false);
  });

  test("createGeneFile", () async {
    final mipgenService = MipgenService();

    await mipgenService.createProject("geneFileTest");
    List<String> genes = ["BART1", "SN1PZ1"];

    await mipgenService.createGeneFile("geneFileTest", genes);
    expect(
        await File("${mipgenService.projectFolder}/geneFileTest/genes.txt")
            .exists(),
        true);

    mipgenService.deleteProject("geneFileTest");
  });

  test("createBedFile", () async {
    final mipgenService = MipgenService();

    await mipgenService.createProject("bedFileTest");
    List<String> genes = ["MYH11"];

    await mipgenService.createGeneFile("bedFileTest", genes);

    await mipgenService.createBedFile("bedFileTest");

    expect(
        await File("${mipgenService.projectFolder}/bedFileTest/genes.bed")
            .exists(),
        true);
    expect(
        await File("${mipgenService.projectFolder}/bedFileTest/genes.bed")
            .length(),
        greaterThan(1024));

    mipgenService.deleteProject("bedFileTest");
  });

  test("generateMips and delete excess files", () async {
    final mipgenService = MipgenService();

    await mipgenService.createProject("mipsTest");
    List<String> genes = ["MYH11"];

    await mipgenService.createGeneFile("mipsTest", genes);

    await mipgenService.createBedFile("mipsTest");

    await mipgenService.generateMips("mipsTest", false);

    expect(
        await File(
            "${mipgenService.projectFolder}/mipsTest/mipsTest.picked_mips.txt")
            .exists(),
        true);
    expect(
        await File(
            "${mipgenService.projectFolder}/mipsTest/mipsTest.picked_mips.txt")
            .length(),
        greaterThan(1024));
    expect(
        await File(
            "${mipgenService.projectFolder}/mipsTest/mipsTest.all_sequences.sai")
            .exists(),
        true);

    await mipgenService.deleteByproducts("mipsTest");

    expect(
        await File(
            "${mipgenService.projectFolder}/mipsTest/mipsTest.all_sequences.sai")
            .exists(),
        false);

    mipgenService.deleteProject("mipsTest");
  });
}
